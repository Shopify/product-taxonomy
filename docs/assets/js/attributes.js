import {q, qq, getQueryParam} from './util.js';

const attributeQueryParamKey = 'attributeId';
const className = {
  hidden: 'hidden',
  visible: 'visible',
};
let selectedAttribute = undefined;
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

export const setAttribute = (attributeId) => {
  selectedAttribute = `gid://shopify/TaxonomyAttribute/${attributeId}`;
  setAttributeQueryParam(attributeId);
  renderPage();
}

const toggleSelectedAttribute = () => {
  const attributeElements = readAttributeValuesElement();
  attributeElements.forEach((element) => {
    if (element.id === selectedAttribute) {
      element.classList.remove(className.hidden);
    } else {
      element.classList.add(className.hidden);
    }
  });
};

const setAttributeQueryParam = (attributeId) => {
  const url = new URL(window.location);
  if (attributeId != null) {
    url.searchParams.set(attributeQueryParamKey, attributeId);
  } else {
    url.searchParams.delete(attributeQueryParamKey);
  }
  window.history.pushState({}, '', url);
};

const renderWithYieldToMain = () => {
  const tasks = [
    toggleSelectedAttribute
    // toggleSelectedCategory,
    // toggleExpandedCategories,
    // toggleVisibleSelectedCategory,
    // toggleVisibleAtrributes,
  ];

  executeTasksWithYieldToMain(tasks);
};

const renderWithScheduler = () => {
  scheduler.postTask(toggleSelectedAttribute, {priority: 'user-blocking'})
  // scheduler.postTask(toggleSelectedCategory, {priority: 'user-blocking'});
  // scheduler.postTask(toggleExpandedCategories, {priority: 'user-blocking'});
  // scheduler.postTask(toggleVisibleSelectedCategory);
  // scheduler.postTask(toggleVisibleAtrributes);
};

let scheduleRenderPage = undefined;
let scheduleAttributeTitleClick = undefined;

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

const addOnClick = (target, handler) => {
  target.addEventListener('click', handler);
  target.addEventListener('keypress', (e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      target.dispatchEvent(new Event('click'));
    }
  });
};

const setupListeners = () => {
  const categoryNodeElements = readCategoryNodeElements();
  const attributeTitleElements = qq('.attribute-title');

  categoryNodeElements.forEach((element) => {
    addOnClick(element, () =>
      toggleNode(
        element.id,
        element.closest('.category-level').dataset.nodeDepth,
      ),
    );
  });

  attributeTitleElements.forEach((element) =>
    addOnClick(element, scheduleAttributeTitleClick),
  );
};

export const setupAttributes = () => {
  initSchedulerFunctions();
  // setupListeners();
  renderPage();
};
