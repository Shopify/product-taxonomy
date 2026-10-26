// Loads the JSON written by docs/_plugins/release_data.rb.

// Must match SHARD_COUNT and shard_for in docs/_plugins/release_data.rb.
const SHARD_COUNT = 256;
const encoder = new TextEncoder();
const jsonCache = new Map();

// FNV-1a (32-bit) over the UTF-8 bytes of the key, formatted as two hex digits.
const shardFor = (key) => {
  let hash = 0x811c9dc5;
  for (const byte of encoder.encode(key)) {
    hash = Math.imul(hash ^ byte, 0x01000193) >>> 0;
  }
  return (hash % SHARD_COUNT).toString(16).padStart(2, '0');
};

// Fetches a JSON file once; failed requests are dropped from the cache so they can be retried.
export const fetchJson = (url) => {
  if (!jsonCache.has(url)) {
    const request = fetch(url).then((response) => {
      if (!response.ok) throw new Error(`Failed to load ${url}: ${response.status}`);
      return response.json();
    });
    request.catch(() => jsonCache.delete(url));
    jsonCache.set(url, request);
  }
  return jsonCache.get(url);
};

// Returns the record stored under `key` in the sharded directory `dir`, or undefined.
// Every shard file is written, even when empty, so any failed request is an error.
export const fetchRecord = async (dir, key) => {
  const shard = await fetchJson(`${dir}/${shardFor(String(key))}.json`);
  return Object.hasOwn(shard, key) ? shard[key] : undefined;
};

export const createElement = (tagName, className, text) => {
  const element = document.createElement(tagName);
  if (className) element.className = className;
  if (text != null) element.textContent = text;
  return element;
};

// Builds a `.values-container__list-item` entry: the item name followed by an optional `.id` line.
export const createListItem = (text, id) => {
  const content = createElement('div', 'values-container__list-item-content', text);
  if (id != null) content.append(createElement('div', 'id', id));
  const item = createElement('li', 'values-container__list-item');
  item.append(content);
  return item;
};

// Shows a load error with a retry button just before `container`, or clears it when `retry` is omitted.
export const setLoadError = (container, retry) => {
  const existing = container.previousElementSibling;
  if (existing?.classList.contains('release-data-error')) existing.remove();
  if (!retry) return;

  const button = createElement('button', null, 'Try again');
  button.type = 'button';
  button.addEventListener('click', retry);
  const error = createElement('p', 'release-data-error', 'Unable to load details. Please try again. ');
  error.setAttribute('role', 'alert');
  error.append(button);
  container.before(error);
};

// Replaces the children of `parent` with `children`; avoids spreading very long arrays into one call.
export const replaceChildrenWith = (parent, children) => {
  const fragment = document.createDocumentFragment();
  children.forEach((child) => fragment.append(child));
  parent.replaceChildren(fragment);
};
