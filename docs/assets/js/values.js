import {qq} from './util.js';

const valueQueryParamKey = 'valueHandle';
const className = {
  hidden: 'hidden',
  visible: 'visible',
};
let cachedElements = {};

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

const readValueEntryElements = () => {
  if (cachedElements.valueEntryElements) {
    return cachedElements.valueEntryElements;
  } else {
    return (cachedElements.valueEntryElements = qq('.value-page-entry'));
  }
};

export const setValue = (valueHandle) => {
  setValueQueryParam(valueHandle);
  renderPage();
};

const toggleSelectedValue = () => {
  const valueElements = readValueEntryElements();
  const selectedValue = new URLSearchParams(window.location.search).get(valueQueryParamKey);
  valueElements.forEach((element) => {
    if (element.dataset.handle === selectedValue) {
      element.classList.remove(className.hidden);
    } else {
      element.classList.add(className.hidden);
    }
  });
};

const setValueQueryParam = (valueHandle) => {
  const url = new URL(window.location);
  if (valueHandle != null) {
    url.searchParams.set(valueQueryParamKey, valueHandle);
  } else {
    url.searchParams.delete(valueQueryParamKey);
  }
  window.history.pushState({}, '', url);
};

const renderWithYieldToMain = () => {
  const tasks = [toggleSelectedValue];
  executeTasksWithYieldToMain(tasks);
};

const renderWithScheduler = () => {
  scheduler.postTask(toggleSelectedValue, {priority: 'user-blocking'});
};

let scheduleRenderPage = undefined;

const initSchedulerFunctions = () => {
  if ('scheduler' in window) {
    scheduleRenderPage = renderWithScheduler;
  } else {
    scheduleRenderPage = renderWithYieldToMain;
  }
};

const renderPage = () => {
  scheduleRenderPage();
};

export const setupValues = () => {
  initSchedulerFunctions();
  renderPage();
};
