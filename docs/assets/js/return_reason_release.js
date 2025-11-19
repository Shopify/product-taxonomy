import {setupSearch} from './search.js';
import {q, qq, getQueryParam} from './util.js';

const returnReasonQueryParamKey = 'returnReasonHandle';

const showReturnReasonByHandle = (returnReasonHandle) => {
  const returnReasonContainers = qq('.return-reason-container');
  returnReasonContainers.forEach((container) => {
    if (container.dataset.handle === returnReasonHandle) {
      container.classList.remove('hidden');
    } else {
      container.classList.add('hidden');
    }
  });
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
      {name: 'title', score: 1},
      {name: 'return_reason.name', score: 1},
      {name: 'return_reason.description', score: 0.5},
    ],
  );
  setInitialReturnReason();
});

