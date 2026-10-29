# JavaScript Coding Guidelines

Style rules for all browser and Node JavaScript. The cross-language rules (naming basics, control flow, error-message content, comment style, safety) live in CODE_REVIEW.md and are not repeated here.

## Declarations

`let` and `const` are in the temporal dead zone until their declaration runs, so a function called during setup cannot read a binding declared below that call. Declare module state above every call that can reach it, and keep a test that mounts the view once from scratch.

Bad: `mount()` calls `load()` before the declaration is reached, so the module throws and the view stays blank.

```javascript
function load() {
    requestNumber += 1;
}

mount();

let requestNumber = 0;
```

Good:

```javascript
let requestNumber = 0;

function load() {
    requestNumber += 1;
}

mount();
```

## Stale Async Responses

A view that can be replaced while an `await` is in flight follows every `await` with a check of a request counter. Use one counter per kind of request, because a load and a click are different kinds and must not cancel each other. Check it in the `catch` too, or a failed old request overwrites the new view with an error.

```javascript
let loadNumber = 0;

async function loadThread(threadId) {
    const thisLoad = ++loadNumber;
    try {
        const thread = await fetchThread(threadId);
        if (thisLoad !== loadNumber) {
            return;
        }
        renderThread(thread);
    } catch (error) {
        if (thisLoad !== loadNumber) {
            return;
        }
        showError(error);
    }
}
```

## Pending Actions

A poll that redraws the view also redraws a button that was disabled while its request was in flight, enabled again, so a second click repeats the action. Keep the pending state in the module, outside the view, and clear it only when the server's data shows the change.

```javascript
// Job id to the run number shown when Restart was clicked.
const pendingRestarts = new Map();

function renderJob(job) {
    if (job.runNumber > pendingRestarts.get(job.id)) {
        pendingRestarts.delete(job.id);
    }
    const button = document.createElement('button');
    button.textContent = 'Restart';
    button.disabled = pendingRestarts.has(job.id);
    button.addEventListener('click', () => {
        pendingRestarts.set(job.id, job.runNumber);
        button.disabled = true;
        restartJob(job.id).catch((error) => {
            pendingRestarts.delete(job.id);
            showError(error);
        });
    });
    return button;
}
```

Not:

The next poll builds a new, enabled button while the restart is still waiting:

```javascript
function renderJob(job) {
    const button = document.createElement('button');
    button.textContent = 'Restart';
    button.addEventListener('click', () => {
        button.disabled = true;
        restartJob(job.id).catch(showError);
    });
    return button;
}
```

## Failed Refreshes

Decide once, in the function that makes every request, whether a failure means the server is away. Only no answer at all and a 5xx status mean that; a 4xx or a response that won't parse is a bug to show. When the server is away, keep the last good view on screen, dimmed, instead of replacing it with an error.

```javascript
class ServerAwayError extends Error {}

async function request(url) {
    let response;
    try {
        response = await fetch(url);
    } catch (error) {
        throw new ServerAwayError(`no answer from ${url}: ${error.message}`);
    }
    if (response.status >= 500) {
        throw new ServerAwayError(`${url} returned ${response.status}`);
    }
    if (!response.ok) {
        throw new Error(`${url} returned ${response.status}`);
    }
    return response.json();
}

async function refreshJobs(view) {
    try {
        renderJobs(view, await request('/api/jobs'));
        view.classList.remove('stale');
    } catch (error) {
        if (error instanceof ServerAwayError) {
            view.classList.add('stale');
            return;
        }
        showError(error);
    }
}
```

## Timers

Every `setInterval`, `setTimeout`, and poll loop has an owner that stops it when its view is torn down and when the user signs out. A timer nobody stops keeps running after sign-out, requesting with no session and drawing into a view that is gone.

```javascript
// A guess; jobs change on the order of minutes, so 5s feels live without loading the server.
const POLL_MILLISECONDS = 5000;

function mountJobs(view) {
    const pollTimer = setInterval(() => refreshJobs(view), POLL_MILLISECONDS);
    return function unmountJobs() {
        clearInterval(pollTimer);
    };
}
```

Not:

```javascript
function mountJobs(view) {
    setInterval(() => refreshJobs(view), POLL_MILLISECONDS);
}
```

## Promise Rejections

Every promise started from an event handler ends in a catch, so a failure shows a message instead of an unhandled rejection the user never sees.

```javascript
// Good
button.addEventListener('click', () => {
    loadThread(threadId).catch(showError);
});

// Bad
button.addEventListener('click', () => {
    loadThread(threadId);
});
```

## Text, Never HTML

Put data into the DOM with `textContent`. Never assign `innerHTML` from data, no matter where the data came from.

```javascript
// Good
cell.textContent = message.author;

// Bad
cell.innerHTML = message.author;
```

## Ids From URLs and JSON

An id taken from a URL or a JSON payload is digits only, then converted and checked with `Number.isSafeInteger`. Past 2^53 the conversion is silent and wrong: `Number("9007199254740993")` is `9007199254740992`, a different id. Keep the id as a string when it only has to be compared or passed through.

```javascript
if (!/^[0-9]+$/.test(rawId)) {
    throw new Error(`id must be digits, got: ${rawId}`);
}
const threadId = Number(rawId);
if (!Number.isSafeInteger(threadId)) {
    throw new Error(`id is too large to represent exactly: ${rawId}`);
}
```

## Modules and Tests

Logic lives in modules that touch no DOM, so it can be tested directly. Run those tests under the oldest Node the project supports, not just the newest on the developer's machine. The untested glue that wires modules to the page is where the late bugs show up, so keep it thin enough to read.

## Verification

After writing or editing JavaScript, run `node --check <file>` to verify syntax.
