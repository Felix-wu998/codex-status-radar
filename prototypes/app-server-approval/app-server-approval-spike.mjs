const port = process.env.CODEX_APP_SERVER_PORT || "8794";
const cwd = process.env.CODEX_SPIKE_CWD || "/Users/wuzhentian/Project/临时白板";
const wsUrl = `ws://127.0.0.1:${port}`;
const approvalResponseDelayMs = Number(process.env.CODEX_SPIKE_APPROVAL_RESPONSE_DELAY_MS || "0");

let nextId = 1;
let threadId = null;
let sawWaitingOnApproval = false;
let sawApprovalRequest = false;
let capturedApproval = null;

const pending = new Map();
const ws = new WebSocket(wsUrl);

function send(method, params) {
  const id = nextId++;
  const message = { method, id, params };
  console.log("SEND", JSON.stringify(message));
  ws.send(JSON.stringify(message));

  return new Promise((resolve, reject) => {
    pending.set(id, { resolve, reject, method });
  });
}

function respond(id, result) {
  const message = { id, result };
  console.log("RESPOND", JSON.stringify(message));
  ws.send(JSON.stringify(message));
}

function summarize(reason) {
  console.log(
    "SUMMARY",
    JSON.stringify(
      {
        reason,
        threadId,
        sawWaitingOnApproval,
        sawApprovalRequest,
        capturedApproval,
      },
      null,
      2,
    ),
  );
}

const timeout = setTimeout(() => {
  summarize("timeout");
  ws.close();
  process.exit(sawApprovalRequest ? 0 : 3);
}, 90_000);

ws.onopen = async () => {
  try {
    const init = await send("initialize", {
      clientInfo: {
        name: "codex-status-radar-spike",
        title: "Codex Status Radar Spike",
        version: "0.0.1",
      },
      capabilities: { experimentalApi: true },
    });
    console.log("INIT_RESULT", JSON.stringify(init));

    ws.send(JSON.stringify({ method: "initialized" }));

    const thread = await send("thread/start", {
      cwd,
      approvalPolicy: "on-request",
      approvalsReviewer: "user",
      sandbox: "read-only",
      ephemeral: true,
      experimentalRawEvents: false,
      persistExtendedHistory: false,
    });

    threadId = thread.thread.id;
    console.log("THREAD_ID", threadId);
    console.log("THREAD_APPROVAL_POLICY", JSON.stringify(thread.approvalPolicy));
    console.log("THREAD_SANDBOX", JSON.stringify(thread.sandbox));

    await send("turn/start", {
      threadId,
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
  } catch (error) {
    console.error("ERROR", JSON.stringify(error));
    clearTimeout(timeout);
    process.exit(1);
  }
};

ws.onmessage = (event) => {
  const raw = event.data;
  console.log("RECV", raw.length > 3000 ? `${raw.slice(0, 3000)}...<truncated>` : raw);

  let message;
  try {
    message = JSON.parse(raw);
  } catch {
    return;
  }

  if (message.id !== undefined && pending.has(message.id)) {
    const pendingRequest = pending.get(message.id);
    pending.delete(message.id);
    if (message.error) {
      pendingRequest.reject(message.error);
    } else {
      pendingRequest.resolve(message.result);
    }
    return;
  }

  if (message.method === "thread/status/changed") {
    const flags = message.params?.status?.activeFlags || [];
    if (flags.includes("waitingOnApproval")) {
      sawWaitingOnApproval = true;
    }
  }

  if (message.method === "item/commandExecution/requestApproval") {
    sawApprovalRequest = true;
    capturedApproval = {
      availableDecisions: message.params.availableDecisions || null,
      command: message.params.command || null,
      cwd: message.params.cwd || null,
      reason: message.params.reason || null,
      itemId: message.params.itemId,
      approvalId: message.params.approvalId || null,
    };

    console.log("APPROVAL_CAPTURED", JSON.stringify(capturedApproval, null, 2));

    // The spike declines the test command so it does not create the /tmp test file.
    setTimeout(() => {
      respond(message.id, { decision: "decline" });
    }, approvalResponseDelayMs);
  }

  if (message.method === "turn/completed") {
    summarize("turn_completed");
    clearTimeout(timeout);
    ws.close();
    process.exit(sawApprovalRequest ? 0 : 4);
  }
};

ws.onerror = (event) => {
  console.error("WS_ERROR", event.message || event);
};

ws.onclose = (event) => {
  console.log("CLOSE", event.code, event.reason);
};
