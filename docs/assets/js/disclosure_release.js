import {setupSearch} from './search.js';
import {qq, getQueryParam} from './util.js';

const disclosureQueryParamKey = 'disclosureId';

const showDisclosureByPublicId = (publicId) => {
  const disclosureContainers = qq('.return-reason-container');
  disclosureContainers.forEach((container) => {
    if (container.dataset.publicId === publicId) {
      container.classList.remove('hidden');
    } else {
      container.classList.add('hidden');
    }
  });
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
  setInitialDisclosure();
});
