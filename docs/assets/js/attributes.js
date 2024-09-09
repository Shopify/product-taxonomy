import {qq} from './util.js';

const attributeQueryParamKey = 'attributeHandle';
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


const readAttributeValuesElement = () => {
  if (cachedElements.attributeValuesElement) {
    return cachedElements.attributeValuesElement;
  } else {
    return (cachedElements.attributeValuesElement = qq('.attribute-container'));
  }
};

export const setAttribute = (attributeHandle) => {
  setAttributeQueryParam(attributeHandle);
  renderPage();
}

const toggleSelectedAttribute = () => {
  const attributeElements = readAttributeValuesElement();
  const selectedAttribute = new URLSearchParams(window.location.search).get(attributeQueryParamKey);
  attributeElements.forEach((element) => {
    if (element.dataset.handle === selectedAttribute) {
      element.classList.remove(className.hidden);
    } else {
      element.classList.add(className.hidden);
    }
  });
};

const setAttributeQueryParam = (attributeHandle) => {
  const url = new URL(window.location);
  if (attributeHandle != null) {
    url.searchParams.set(attributeQueryParamKey, attributeHandle);
  } else {
    url.searchParams.delete(attributeQueryParamKey);
  }
  window.history.pushState({}, '', url);
};

const renderWithYieldToMain = () => {
  const tasks = [
    toggleSelectedAttribute
  ];

  executeTasksWithYieldToMain(tasks);
};

const renderWithScheduler = () => {
  scheduler.postTask(toggleSelectedAttribute, {priority: 'user-blocking'})
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

export const setupAttributes = () => {
  initSchedulerFunctions();
  renderPage();
};
