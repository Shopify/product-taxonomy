import {qq} from './util.js';

const returnReasonQueryParamKey = 'returnReasonHandle';
const className = {
  hidden: 'hidden',
  visible: 'visible',
};
let cachedElements = {
};

const yieldToMain = () => {
  return new Promise((resolve) => {
    setTimeout(resolve, 0);
  });
};

const executeTasksWithYieldToMain = async (tasks) => {
  while (tasks.length > 0) {
    const task = tasks.shift();
    task();
    await yieldToMain();
  }
};


const readReturnReasonValuesElement = () => {
  if (cachedElements.returnReasonValuesElement) {
    return cachedElements.returnReasonValuesElement;
  } else {
    return (cachedElements.returnReasonValuesElement = qq('.return-reason-container'));
  }
};

export const setReturnReason = (returnReasonHandle) => {
  setReturnReasonQueryParam(returnReasonHandle);
  renderPage();
}

const toggleSelectedReturnReason = () => {
  const returnReasonElements = readReturnReasonValuesElement();
  const selectedReturnReason = new URLSearchParams(window.location.search).get(returnReasonQueryParamKey);
  returnReasonElements.forEach((element) => {
    if (element.dataset.handle === selectedReturnReason) {
      element.classList.remove(className.hidden);
    } else {
      element.classList.add(className.hidden);
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

const renderWithYieldToMain = () => {
  const tasks = [
    toggleSelectedReturnReason
  ];

  executeTasksWithYieldToMain(tasks);
};

const renderWithScheduler = () => {
  scheduler.postTask(toggleSelectedReturnReason, {priority: 'user-blocking'})
};

let scheduleRenderPage = undefined;

const initSchedulerFunctions = () => {
  if ('scheduler' in window) {
    scheduleRenderPage = renderWithScheduler;
    return;
  } else {
    scheduleRenderPage = renderWithYieldToMain;
    return;
  }
};

const renderPage = () => {
  scheduleRenderPage();
};

export const setupReturnReasons = () => {
  initSchedulerFunctions();
  renderPage();
};




