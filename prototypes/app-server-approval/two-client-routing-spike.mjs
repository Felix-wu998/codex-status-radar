const port = process.env.CODEX_APP_SERVER_PORT || "8794";
const cwd = process.env.CODEX_SPIKE_CWD || "/Users/wuzhentian/Project/临时白板";
const wsUrl = `ws://127.0.0.1:${port}`;
const approvalResponseDelayMs = Number(process.env.CODEX_SPIKE_APPROVAL_RESPONSE_DELAY_MS || "0");
const ephemeralThread = process.env.CODEX_SPIKE_EPHEMERAL === "1";
const expectedRouting = process.env.CODEX_EXPECT_OBSERVER_APPROVAL === "1"
  ? "observer_receives_approval"
  : "actor_only";
const verbose = process.env.CODEX_ROUTING_SPIKE_VERBOSE === "1";

const summary = {
  expectedRouting,
  threadId: null,
  ephemeralThread,
  observerResume: {
    ok: false,
    error: null,
  },
  actor: {
    sawWaitingOnApproval: false,
    sawApprovalRequest: false,
    capturedApproval: null,
  },
  observer: {
    sawWaitingOnApproval: false,
    sawApprovalRequest: false,
    capturedApproval: null,
  },
};

class AppServerClient {
  constructor(name) {
    this.name = name;
    this.nextId = 1;
    this.pending = new Map();
    this.ws = new WebSocket(wsUrl);
    this.opened = new Promise((resolve, reject) => {
      this.ws.onopen = resolve;
      this.ws.onerror = (event) => {
        reject(new Error(event.message || `${name} WebSocket error`));
      };
    });
    this.closed = false;

    this.ws.onmessage = (event) => {
      this.handleMessage(event.data);
    };
    this.ws.onclose = (event) => {
      this.closed = true;
      if (verbose) {
        console.log(`${this.name} CLOSE`, event.code, event.reason);
      }
    };
  }

  async initialize() {
    await this.opened;
    const init = await this.send("initialize", {
      clientInfo: {
        name: `codex-status-radar-${this.name}`,
        title: `Codex Status Radar ${this.name}`,
        version: "0.0.1",
      },
      capabilities: { experimentalApi: true },
    });
    this.notify("initialized");
    if (verbose) {
      console.log(`${this.name} INIT_RESULT`, JSON.stringify(init));
    }
  }

  send(method, params) {
    const id = this.nextId++;
    const message = { method, id, params };
    console.log(`${this.name} SEND`, JSON.stringify(message));
    this.ws.send(JSON.stringify(message));

    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject, method });
    });
  }

  respond(id, result) {
    const message = { id, result };
    console.log(`${this.name} RESPOND`, JSON.stringify(message));
    this.ws.send(JSON.stringify(message));
  }

  notify(method, params) {
    const message = params === undefined ? { method } : { method, params };
    console.log(`${this.name} NOTIFY`, JSON.stringify(message));
    this.ws.send(JSON.stringify(message));
  }

  close() {
    if (!this.closed) {
      this.ws.close();
    }
  }

  handleMessage(raw) {
    const text = String(raw);
    if (verbose) {
      console.log(`${this.name} RECV`, text.length > 3000 ? `${text.slice(0, 3000)}...<truncated>` : text);
    }

    let message;
    try {
      message = JSON.parse(text);
    } catch {
      return;
    }

    if (message.id !== undefined && this.pending.has(message.id)) {
      const pendingRequest = this.pending.get(message.id);
      this.pending.delete(message.id);
      if (message.error) {
        pendingRequest.reject(message.error);
      } else {
        pendingRequest.resolve(message.result);
      }
      return;
    }

    observeProtocolEvent(this, message);
  }
}

let actor;
let observer;
let finished = false;

const timeout = setTimeout(() => {
  finish("timeout", 3);
}, 90_000);

function observeProtocolEvent(client, message) {
  const bucket = summary[client.name];
  if (!bucket) {
    return;
  }

  if (message.method === "thread/status/changed") {
    const flags = message.params?.status?.activeFlags || [];
    if (flags.includes("waitingOnApproval")) {
      bucket.sawWaitingOnApproval = true;
      console.log(`${client.name} SAW_WAITING_ON_APPROVAL`);
    }
  }

  if (message.method === "item/commandExecution/requestApproval") {
    bucket.sawApprovalRequest = true;
    bucket.capturedApproval = {
      availableDecisions: message.params.availableDecisions || null,
      command: message.params.command || null,
      cwd: message.params.cwd || null,
      reason: message.params.reason || null,
      itemId: message.params.itemId,
      approvalId: message.params.approvalId || null,
    };
    console.log(`${client.name} APPROVAL_CAPTURED`, JSON.stringify(bucket.capturedApproval, null, 2));

    if (client.name === "actor") {
      setTimeout(() => {
        client.respond(message.id, { decision: "decline" });
      }, approvalResponseDelayMs);
    }
  }

  if (client.name === "actor" && message.method === "turn/completed") {
    setTimeout(() => {
      finish("turn_completed", routingExitCode());
    }, 500);
  }
}

function routingExitCode() {
  if (!summary.actor.sawApprovalRequest) {
    return 4;
  }
  if (!summary.observer.sawWaitingOnApproval) {
    return 5;
  }

  if (expectedRouting === "observer_receives_approval") {
    return summary.observer.sawApprovalRequest ? 0 : 6;
  }

  return summary.observer.sawApprovalRequest ? 7 : 0;
}

function finish(reason, exitCode) {
  if (finished) {
    return;
  }
  finished = true;
  clearTimeout(timeout);

  const result = exitCode === 0 ? "pass" : "fail";
  console.log(
    "ROUTING_SUMMARY",
    JSON.stringify(
      {
        reason,
        result,
        ...summary,
      },
      null,
      2,
    ),
  );

  actor?.close();
  observer?.close();
  process.exit(exitCode);
}

async function main() {
  actor = new AppServerClient("actor");
  observer = new AppServerClient("observer");

  await Promise.all([actor.initialize(), observer.initialize()]);

  const thread = await actor.send("thread/start", {
    cwd,
    approvalPolicy: "on-request",
    approvalsReviewer: "user",
    sandbox: "read-only",
    ephemeral: ephemeralThread,
    experimentalRawEvents: false,
    persistExtendedHistory: false,
  });

  summary.threadId = thread.thread.id;
  console.log("THREAD_ID", summary.threadId);

  try {
    await observer.send("thread/resume", {
      threadId: summary.threadId,
      persistExtendedHistory: false,
    });
    summary.observerResume.ok = true;
    console.log("OBSERVER_RESUMED_THREAD", summary.threadId);
  } catch (error) {
    summary.observerResume.error = error?.message || String(error);
    console.log("OBSERVER_RESUME_FAILED", summary.observerResume.error);
  }

  await actor.send("turn/start", {
    threadId: summary.threadId,
    input: [
      {
        type: "text",
        text:
          "请只执行一个 shell 命令：`touch /tmp/codex-status-radar-approval-test.txt`。" +
          "如果只读沙箱或权限策略阻止写入，请必须请求审批后重试同一个命令；不要做其他事情。",
        text_elements: [],
      },
    ],
    approvalPolicy: "on-request",
    approvalsReviewer: "user",
    sandboxPolicy: {
      type: "readOnly",
      access: { type: "fullAccess" },
      networkAccess: false,
    },
    effort: "low",
  });

  console.log("TURN_STARTED_REQUEST_ACCEPTED");
}

main().catch((error) => {
  console.error("ERROR", error.stack || error.message || String(error));
  finish("error", 1);
});
