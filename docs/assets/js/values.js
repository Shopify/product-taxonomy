import {q, getQueryParam} from './util.js';
import {fetchRecord, createElement} from './release_data.js';

const valueQueryParamKey = 'valueHandle';
const className = {
  hidden: 'hidden',
  visible: 'visible',
};
const valueDataDir = '../value_data';

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

export const setValue = (valueHandle) => {
  setValueQueryParam(valueHandle);
  renderPage();
};

const renderSelectedValue = async () => {
  const container = q('#value-detail');
  const selectedValue = getQueryParam(valueQueryParamKey);
  container.classList.add(className.hidden);
  if (!selectedValue) return;

  const value = await fetchRecord(valueDataDir, selectedValue);
  // Skip stale responses when another value was selected while loading.
  if (!value || getQueryParam(valueQueryParamKey) !== selectedValue) return;

  q('.value-detail__name', container).textContent = value.name;
  q('.value-detail__id', container).textContent = value.id;
  q('.value-detail__handle', container).textContent = value.handle;

  const attribute = q('.value-detail__attribute', container);
  if (value.attribute) {
    const link = createElement('a', null, value.attribute.name);
    link.href = `${container.dataset.attributesUrl}?attributeHandle=${encodeURIComponent(value.attribute.handle)}`;
    attribute.replaceChildren(link);
  } else {
    attribute.replaceChildren('No attribute associated.');
  }
  container.dataset.handle = value.handle;
  container.classList.remove(className.hidden);
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
  const tasks = [renderSelectedValue];
  executeTasksWithYieldToMain(tasks);
};

const renderWithScheduler = () => {
  scheduler.postTask(renderSelectedValue, {priority: 'user-blocking'});
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
