import {q, qq, getQueryParam} from './util.js';

const nodeQueryParamKey = 'categoryId';
const className = {
  hidden: 'hidden',
  visible: 'visible',
};
let selectedNodes = {};
let selectedNode = undefined;
let cachedElements = {
  mappingElements: undefined,
  categoryLevelElements: undefined,
  categoryNodeElements: undefined,
  selectedCategoryContainerElements: undefined,
  attributeValuesElement: undefined,
  returnReasonValuesElement: undefined,
  selectedCategoryTitle: undefined,
  categoryAttributesTitle: undefined,
  categoryReturnReasonsTitle: undefined,
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

const readMappingElements = () => {
  if (cachedElements.mappingElements) {
    return cachedElements.mappingElements;
  } else {
    return (cachedElements.mappingElements = qq('.mapped-category'));
  }
};

const readCategoryLevelElements = () => {
  if (cachedElements.categoryLevelElements) {
    return cachedElements.categoryLevelElements;
  } else {
    return (cachedElements.categoryLevelElements = qq('.category-level'));
  }
};

const readCategoryNodeElements = () => {
  if (cachedElements.categoryNodeElements) {
    return cachedElements.categoryNodeElements;
  } else {
    return (cachedElements.categoryNodeElements = qq('.category-node'));
  }
};

const readSelectedCategoryContainerElements = () => {
  if (cachedElements.selectedCategoryContainerElements) {
    return cachedElements.selectedCategoryContainerElements;
  } else {
    return qq('.selected-category');
  }
};

const readAttributeValuesElement = () => {
  if (cachedElements.attributeValuesElement) {
    return cachedElements.attributeValuesElement;
  } else {
    return (cachedElements.attributeValuesElement = qq('.attribute-values'));
  }
};

const readReturnReasonValuesElement = () => {
  if (cachedElements.returnReasonValuesElement) {
    return cachedElements.returnReasonValuesElement;
  } else {
    return (cachedElements.returnReasonValuesElement = qq('.return-reason-values'));
  }
};

const readSelectedCategoryTitle = () => {
  if (cachedElements.selectedCategoryTitle) {
    return cachedElements.selectedCategoryTitle;
  } else {
    return (cachedElements.selectedCategoryTitle = q(
      '#selected-category-title',
    ));
  }
};

const readCategoryAttributesTitle = () => {
  if (cachedElements.categoryAttributesTitle) {
    return cachedElements.categoryAttributesTitle;
  } else {
    return (cachedElements.categoryAttributesTitle = q(
      '#category-attributes-title',
    ));
  }
};

const readCategoryReturnReasonsTitle = () => {
  if (cachedElements.categoryReturnReasonsTitle) {
    return cachedElements.categoryReturnReasonsTitle;
  } else {
    return (cachedElements.categoryReturnReasonsTitle = q(
      '#category-return-reasons-title',
    ));
  }
};

const toggleExpandedCategories = () => {
  const categoryLevelElements = readCategoryLevelElements();

  categoryLevelElements.forEach((element) => {
    const parentId = element.dataset.parentId;
    const depth = element.dataset.nodeDepth - 1;
    const classes = element.classList;

    if (selectedNodes[depth] === parentId) {
      classes.replace(className.hidden, className.visible);
    } else {
      classes.replace(className.visible, className.hidden);
    }
  });
};

const toggleSelectedCategory = () => {
  const selectedNodeIds = Object.values(selectedNodes);
  const categoryNodeElements = readCategoryNodeElements();

  categoryNodeElements.forEach((element) => {
    const nodeId = element.id;
    const classes = element.classList;
    if (selectedNodeIds.includes(nodeId)) {
      classes.add('selected');
    } else {
      classes.remove('selected');
    }
  });
};

const toggleVisibleSelectedCategory = () => {
  const selectedCategoryContainerElements =
    readSelectedCategoryContainerElements();
  const selectedCategoryTitle = readSelectedCategoryTitle();
  const categoryAttributesTitle = readCategoryAttributesTitle();
  const categoryReturnReasonsTitle = readCategoryReturnReasonsTitle();

  selectedCategoryContainerElements.forEach((element) => {
    const nodeId = element.id;
    const classes = element.classList;

    if (selectedNode === nodeId) {
      const selectedNodeTitle =
        element.firstElementChild.firstElementChild.dataset
          .selectedCategoryName;
      selectedCategoryTitle.innerText = selectedNodeTitle;
      categoryAttributesTitle.innerText = `${selectedNodeTitle} attributes`;
      categoryReturnReasonsTitle.innerText = `${selectedNodeTitle} return reasons`;
      classes.replace(className.hidden, className.visible);
    } else {
      classes.replace(className.visible, className.hidden);
    }
  });
};

const toggleVisibleAttributes = () => {
  const attributeElements = readAttributeValuesElement();
  const documentNode = q(`.category-node[id="${selectedNode}"]`);

  if (!documentNode) {
    return attributeElements.forEach((element) =>
      element.classList.replace(className.visible, className.hidden),
    );
  }

  const attributeHandles = documentNode.dataset.attributeHandles;
  const attributesList = attributeHandles.split(',');
  attributeElements.forEach((element) => {
    const valueId = element.dataset.handle;
    const classes = element.classList;
    if (attributesList.includes(valueId)) {
      classes.replace(className.hidden, className.visible);
    } else {
      classes.replace(className.visible, className.hidden);
    }
  });
};

const toggleVisibleReturnReasons = () => {
  const returnReasonElements = readReturnReasonValuesElement();
  const documentNode = q(`.category-node[id="${selectedNode}"]`);

  if (!documentNode) {
    return returnReasonElements.forEach((element) =>
      element.classList.replace(className.visible, className.hidden),
    );
  }

  const returnReasonHandles = documentNode.dataset.returnReasonHandles;
  const returnReasonsList = returnReasonHandles ? returnReasonHandles.split(',') : [];
  
  // Create a map of handle to desired order
  const orderMap = {};
  returnReasonsList.forEach((handle, index) => {
    orderMap[handle] = index;
  });
  
  // Convert NodeList to Array and sort
  const returnReasonArray = Array.from(returnReasonElements);
  returnReasonArray.sort((a, b) => {
    const handleA = a.dataset.handle;
    const handleB = b.dataset.handle;
    const orderA = orderMap[handleA] !== undefined ? orderMap[handleA] : 999999;
    const orderB = orderMap[handleB] !== undefined ? orderMap[handleB] : 999999;
    return orderA - orderB;
  });
  
  // Get the parent container
  const container = returnReasonElements[0]?.parentNode;
  if (container) {
    // Reorder the DOM elements
    returnReasonArray.forEach((element) => {
      container.appendChild(element);
    });
  }
  
  // Show/hide based on inclusion in the list
  returnReasonElements.forEach((element) => {
    const valueId = element.dataset.handle;
    const classes = element.classList;
    if (returnReasonsList.includes(valueId)) {
      classes.replace(className.hidden, className.visible);
    } else {
      classes.replace(className.visible, className.hidden);
    }
  });
};

const toggleMappedCategories = () => {
  const mappingElements = readMappingElements();

  mappingElements.forEach((element) => {
    const valueId = element.id;
    const classes = element.classList;
    if (selectedNode === valueId) {
      classes.replace(className.hidden, className.visible);
    } else {
      classes.replace(className.visible, className.hidden);
    }
  });
};

const toggleAttributeSelectedClass = (event) => {
  const element = event.target.closest('.attribute-values');
  element.classList.toggle('selected');
};

const toggleReturnReasonSelectedClass = (event) => {
  const element = event.target.closest('.return-reason-values');
  element.classList.toggle('selected');
};

const toggleMappingSelectedClass = (event) => {
  const element = event.target.parentNode;
  element.classList.toggle('selected');
};

const sendMappingTitleClickAnalytics = () =>
  window.gtag('event', 'app_click', {
    event_action: 'toggle_mapping_visibility',
  });

const sendAttributeTitleClickAnalytics = () =>
  window.gtag('event', 'app_click', {
    event_action: 'toggle_attribute_visibility',
  });

const sendReturnReasonTitleClickAnalytics = () =>
  window.gtag('event', 'app_click', {
    event_action: 'toggle_return_reason_visibility',
  });

const valueTitleClickWithYieldToMain =
  (toggleSelectClassFunc, sendAnalyticsFunc) => (event) => {
    const tasks = [() => toggleSelectClassFunc(event), sendAnalyticsFunc];
    executeTasksWithYieldToMain(tasks);
  };

const valueTitleClickWithScheduler =
  (toggleSelectClassFunc, sendAnalyticsFunc) => (event) => {
    scheduler.postTask(() => toggleSelectClassFunc(event), {
      priority: 'user-blocking',
    });
    scheduler.postTask(sendAnalyticsFunc, {priority: 'background'});
  };

const setNodeQueryParam = (nodeId) => {
  const url = new URL(window.location);
  if (nodeId != null) {
    url.searchParams.set(nodeQueryParamKey, nodeId);
  } else {
    url.searchParams.delete(nodeQueryParamKey);
  }
  window.history.pushState({}, '', url);
};

const renderWithYieldToMain = () => {
  const tasks = [
    toggleSelectedCategory,
    toggleExpandedCategories,
    toggleVisibleSelectedCategory,
    toggleVisibleAttributes,
    toggleVisibleReturnReasons,
    toggleMappedCategories,
  ];

  executeTasksWithYieldToMain(tasks);
};

const renderWithScheduler = () => {
  scheduler.postTask(toggleSelectedCategory, {priority: 'user-blocking'});
  scheduler.postTask(toggleExpandedCategories, {priority: 'user-blocking'});
  scheduler.postTask(toggleVisibleSelectedCategory);
  scheduler.postTask(toggleVisibleAttributes);
  scheduler.postTask(toggleVisibleReturnReasons);
  scheduler.postTask(toggleMappedCategories);
};

let scheduleRenderPage = undefined;
let scheduleMappingTitleClick = undefined;
let scheduleAttributeTitleClick = undefined;
let scheduleReturnReasonTitleClick = undefined;

const initSchedulerFunctions = () => {
  if ('scheduler' in window) {
    scheduleRenderPage = renderWithScheduler;
    scheduleMappingTitleClick = valueTitleClickWithScheduler(
      toggleMappingSelectedClass,
      sendMappingTitleClickAnalytics,
    );
    scheduleAttributeTitleClick = valueTitleClickWithScheduler(
      toggleAttributeSelectedClass,
      sendAttributeTitleClickAnalytics,
    );
    scheduleReturnReasonTitleClick = valueTitleClickWithScheduler(
      toggleReturnReasonSelectedClass,
      sendReturnReasonTitleClickAnalytics,
    );
    return;
  } else {
    scheduleRenderPage = renderWithYieldToMain;
    scheduleMappingTitleClick = valueTitleClickWithYieldToMain(
      toggleMappingSelectedClass,
      sendMappingTitleClickAnalytics,
    );
    scheduleAttributeTitleClick = valueTitleClickWithYieldToMain(
      toggleAttributeSelectedClass,
      sendAttributeTitleClickAnalytics,
    );
    scheduleReturnReasonTitleClick = valueTitleClickWithYieldToMain(
      toggleReturnReasonSelectedClass,
      sendReturnReasonTitleClickAnalytics,
    );
    return;
  }
};

const renderPage = () => {
  scheduleRenderPage();
};

const toggleNode = (nodeId, depth) => {
  if (selectedNodes[depth] === nodeId) {
    delete selectedNodes[depth];
    selectedNode = selectedNodes[depth - 1];
  } else {
    selectedNodes[depth] = nodeId;
    selectedNode = nodeId;
  }
  Object.keys(selectedNodes).forEach((key) => {
    if (key > depth) {
      delete selectedNodes[key];
    }
  });

  setNodeQueryParam(selectedNode);
  renderPage();
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
  const returnReasonTitleElements = qq('.return-reason-title');
  const mappingTitleElements = qq('.mapping-title');

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

  returnReasonTitleElements.forEach((element) =>
    addOnClick(element, scheduleReturnReasonTitleClick),
  );

  mappingTitleElements.forEach((element) =>
    addOnClick(element, scheduleMappingTitleClick),
  );
};

const ensureCategoryGID = (categoryNodeId) => {
  if (!categoryNodeId) return;
  if (categoryNodeId.startsWith('gid://shopify/TaxonomyCategory/'))
    return categoryNodeId;

  return `gid://shopify/TaxonomyCategory/${categoryNodeId}`;
};

const setInitialNode = () => {
  const initialNode = ensureCategoryGID(getQueryParam(nodeQueryParamKey));
  if (!initialNode) return;

  const documentNode = q(`.category-node[id="${initialNode}"]`);
  if (!documentNode) return;

  const ancestors = documentNode.dataset.ancestorIds
    ? documentNode.dataset.ancestorIds.split(',')
    : [];
  const depth = ancestors.length;

  ancestors.forEach((ancestor, index) => {
    selectedNodes[depth - index - 1] = ancestor;
  });
  selectedNodes[depth] = initialNode;
  selectedNode = initialNode;
};

export const resetToCategory = (categoryId) => {
  selectedNodes = {};
  setNodeQueryParam(categoryId);
  setInitialNode();
  renderPage();
};

export const setupNodes = () => {
  initSchedulerFunctions();
  setInitialNode();
  setupListeners();
  renderPage();
};
