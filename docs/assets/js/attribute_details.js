const requests = new Map();
const pendingElements = new WeakMap();

const shardFor = (handle) => {
  let hash = 2166136261;
  for (const byte of new TextEncoder().encode(handle)) {
    hash = Math.imul(hash ^ byte, 16777619) >>> 0;
  }
  return (hash % 256).toString(16).padStart(2, '0');
};

const loadAttributes = (url) => {
  const path = new URL(url, window.location.href).href;
  if (!requests.has(path)) {
    const request = fetch(path)
      .then((response) => {
        if (!response.ok) throw new Error(`Unable to load ${path}: ${response.status}`);
        return response.json();
      })
      .catch((error) => {
        requests.delete(path);
        throw error;
      });
    requests.set(path, request);
  }
  return requests.get(path);
};

const renderItems = (list, items, showIds) => {
  const fragment = document.createDocumentFragment();
  items.forEach((item) => {
    const listItem = document.createElement('li');
    listItem.className = 'values-container__list-item';
    const content = document.createElement('div');
    content.className = 'values-container__list-item-content';
    content.appendChild(document.createTextNode(showIds ? item.name : item.full_name));
    if (showIds) {
      const id = document.createElement('div');
      id.className = 'id';
      id.textContent = item.id;
      content.appendChild(id);
    }
    listItem.appendChild(content);
    fragment.appendChild(listItem);
  });
  list.replaceChildren(fragment);
};

export const populateAttributeDetails = (element, directory, includeCategories = false) => {
  if (element.dataset.detailsLoaded === 'true') return Promise.resolve();
  if (pendingElements.has(element)) return pendingElements.get(element);

  const handle = element.dataset.handle;
  const url = `${directory}/attribute_details_${shardFor(handle)}.json`;
  const request = loadAttributes(url)
    .then((attributes) => {
      const attribute = attributes[handle];
      if (!attribute) throw new Error(`Attribute not found: ${handle}`);
      const values = includeCategories ? attribute.values : attribute.category_values;
      renderItems(element.querySelector('.attribute-values-list'), values, true);
      if (includeCategories) {
        renderItems(element.querySelector('.attribute-categories-list'), attribute.categories, false);
      }
      element.dataset.detailsLoaded = 'true';
    })
    .catch((error) => {
      console.error(error);
      const list = element.querySelector('.attribute-values-list');
      list.textContent = 'Unable to load attribute details. Please try again.';
    })
    .finally(() => pendingElements.delete(element));

  pendingElements.set(element, request);
  return request;
};
