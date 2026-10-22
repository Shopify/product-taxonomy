import {setupSearch} from './search.js';
import {q, getQueryParam} from './util.js';
import {fetchRecord, createListItem, replaceChildrenWith} from './release_data.js';

const returnReasonQueryParamKey = 'returnReasonHandle';
const returnReasonDataDir = '../return_reason_data';

const showReturnReasonByHandle = async (returnReasonHandle) => {
  const container = q('#return-reason-detail');
  container.classList.add('hidden');

  const returnReason = await fetchRecord(returnReasonDataDir, returnReasonHandle);
  // Skip stale responses when another return reason was selected while loading.
  if (!returnReason || getQueryParam(returnReasonQueryParamKey) !== returnReasonHandle) return;

  q('.return-reason-detail__name', container).textContent = returnReason.name;
  q('.return-reason-detail__id', container).textContent = returnReason.id;
  q('.return-reason-description', container).textContent = returnReason.description;
  replaceChildrenWith(
    q('.return-reason-detail__categories', container),
    returnReason.categories.map((fullName) => createListItem(fullName)),
  );
  container.dataset.handle = returnReason.handle;
  container.classList.remove('hidden');
};

const setReturnReasonQueryParam = (returnReasonHandle) => {
  const url = new URL(window.location);
  if (returnReasonHandle != null) {
    url.searchParams.set(returnReasonQueryParamKey, returnReasonHandle);
  } else {
    url.searchParams.delete(returnReasonQueryParamKey);
  }
  window.history.pushState({}, '', url);
};

const resetToReturnReason = (returnReasonHandle) => {
  setReturnReasonQueryParam(returnReasonHandle);
  showReturnReasonByHandle(returnReasonHandle);
};

const setInitialReturnReason = () => {
  const returnReasonHandle = getQueryParam(returnReasonQueryParamKey);
  if (returnReasonHandle) {
    showReturnReasonByHandle(returnReasonHandle);
  }
};

document.addEventListener('DOMContentLoaded', () => {
  setupSearch(
    'return-reason-search',
    'return-reason-search-results',
    '../return_reason_search_index.json',
    resetToReturnReason,
    10,
    [
      {name: 'title', weight: 1},
      {name: 'return_reason.name', weight: 1},
      {name: 'return_reason.description', weight: 0.5},
    ],
  );
  setInitialReturnReason();
});

