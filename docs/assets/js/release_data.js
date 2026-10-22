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
// With `missingValue`, a 404 resolves to that value instead of failing.
export const fetchJson = (url, missingValue) => {
  if (!jsonCache.has(url)) {
    const request = fetch(url).then((response) => {
      if (response.status === 404 && missingValue !== undefined) return missingValue;
      if (!response.ok) throw new Error(`Failed to load ${url}: ${response.status}`);
      return response.json();
    });
    request.catch(() => jsonCache.delete(url));
    jsonCache.set(url, request);
  }
  return jsonCache.get(url);
};

// Returns the record stored under `key` in the sharded directory `dir`, or undefined.
// Only non-empty shards are written, so a missing shard file means the key does not exist.
export const fetchRecord = async (dir, key) => {
  const shard = await fetchJson(`${dir}/${shardFor(String(key))}.json`, {});
  return shard[key];
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

// Replaces the children of `parent` with `children`; avoids spreading very long arrays into one call.
export const replaceChildrenWith = (parent, children) => {
  const fragment = document.createDocumentFragment();
  children.forEach((child) => fragment.append(child));
  parent.replaceChildren(fragment);
};
