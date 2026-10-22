import {setupSearch} from './search.js';
import {q, getQueryParam} from './util.js';
import {fetchRecord, createElement, replaceChildrenWith} from './release_data.js';

const disclosureQueryParamKey = 'disclosureId';
const disclosureDataDir = '../disclosure_data';

const createDisclosureNode = (tagName, className, publicId, text) => {
  const node = createElement(tagName, className, text);
  node.tabIndex = 0;
  node.dataset.publicId = publicId;
  return node;
};

const createDetail = (label, ...content) => {
  const detail = createElement('div', 'values-container__list-item-content');
  detail.append(`${label}: `, ...content);
  const item = createElement('li', 'values-container__list-item');
  item.append(detail);
  return item;
};

const createLink = (url) => {
  const link = createElement('a', null, url);
  link.href = url;
  return link;
};

const buildDetails = (disclosure) => {
  const details = [createDetail('Public id', disclosure.public_id)];
  if (disclosure.description != null) details.push(createDetail('Description', disclosure.description));
  if (disclosure.parent_public_id != null) {
    details.push(
      createDetail(
        'Parent',
        createDisclosureNode('span', 'disclosure-node', disclosure.parent_public_id, disclosure.parent_public_id),
      ),
    );
  }
  if (disclosure.jurisdictions != null) details.push(createDetail('Jurisdictions', disclosure.jurisdictions.join(', ')));
  if (disclosure.legal_citation != null) details.push(createDetail('Legal citation', disclosure.legal_citation));
  if (disclosure.symbol != null) details.push(createDetail('Symbol', createLink(disclosure.symbol)));
  if (disclosure.display_requirements != null) {
    details.push(createDetail('Display requirements', disclosure.display_requirements));
  }
  if (disclosure.source != null) details.push(createDetail('Source', createLink(disclosure.source)));
  if (disclosure.title != null) details.push(createDetail('Title', disclosure.title));
  if (disclosure.content_html != null) {
    const content = createDetail('Content');
    const contentElement = content.firstElementChild;
    contentElement.classList.add('disclosure-content');
    // content_html is Markdown rendered at build time from the taxonomy data, as `markdownify` did before.
    contentElement.insertAdjacentHTML('beforeend', disclosure.content_html);
    details.push(content);
  }
  return details;
};

const showDisclosureByPublicId = async (publicId) => {
  const container = q('#disclosure-detail');
  container.classList.add('hidden');

  const disclosure = await fetchRecord(disclosureDataDir, publicId);
  // Skip stale responses when another disclosure was selected while loading.
  if (!disclosure || getQueryParam(disclosureQueryParamKey) !== publicId) return;

  q('.disclosure-detail__name', container).textContent = disclosure.name;
  q('.disclosure-detail__id', container).textContent = disclosure.id;

  const children = disclosure.children || [];
  const childrenWrapper = q('.disclosure-detail__children', container);
  childrenWrapper.classList.toggle('hidden', children.length === 0);
  replaceChildrenWith(
    q('ul', childrenWrapper),
    children.map((child) => {
      const item = createElement('li', 'values-container__list-item');
      item.append(
        createDisclosureNode('div', 'values-container__list-item-content disclosure-node', child.public_id, child.name),
      );
      return item;
    }),
  );
  replaceChildrenWith(q('.disclosure-detail__details', container), buildDetails(disclosure));
  container.dataset.publicId = disclosure.public_id;
  container.classList.remove('hidden');
};

const setDisclosureQueryParam = (publicId) => {
  const url = new URL(window.location);
  if (publicId != null) {
    url.searchParams.set(disclosureQueryParamKey, publicId);
  } else {
    url.searchParams.delete(disclosureQueryParamKey);
  }
  window.history.pushState({}, '', url);
};

const resetToDisclosure = (publicId) => {
  setDisclosureQueryParam(publicId);
  showDisclosureByPublicId(publicId);
};

// Disclosure nodes are rendered on demand, so clicks are handled on the container.
const setupNodeClicks = () => {
  const container = q('#disclosure-detail');
  const nodeFor = (e) => e.target.closest('.disclosure-node');
  container.addEventListener('click', (e) => {
    const node = nodeFor(e);
    if (node) resetToDisclosure(node.dataset.publicId);
  });
  container.addEventListener('keydown', (e) => {
    const node = nodeFor(e);
    if (node && (e.key === 'Enter' || e.key === ' ')) {
      e.preventDefault();
      resetToDisclosure(node.dataset.publicId);
    }
  });
};

const setInitialDisclosure = () => {
  const publicId = getQueryParam(disclosureQueryParamKey);
  if (publicId) {
    showDisclosureByPublicId(publicId);
  }
};

document.addEventListener('DOMContentLoaded', () => {
  setupSearch(
    'disclosure-search',
    'disclosure-search-results',
    '../disclosure_search_index.json',
    resetToDisclosure,
    10,
    [
      {name: 'title', weight: 1},
      {name: 'disclosure.name', weight: 1},
      {name: 'disclosure.description', weight: 0.5},
    ],
  );
  setupNodeClicks();
  setInitialDisclosure();
});
