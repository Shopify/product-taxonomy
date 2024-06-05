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

  selectedCategoryContainerElements.forEach((element) => {
    const nodeId = element.id;
    const classes = element.classList;
    if (selectedNode === nodeId) {
      classes.replace(className.hidden, className.visible);
    } else {
      classes.replace(className.visible, className.hidden);
    }
  });
};

const toggleVisibleAtrributes = () => {
  const attributeElements = readAttributeValuesElement();
  const documentNode = q(`.category-node[id="${selectedNode}"]`);

  if (!documentNode) {
    return attributeElements.forEach((element) =>
      element.classList.replace(className.visible, className.hidden),
    );
  }

  const attributeIds = documentNode.dataset.attributeIds;
  const attributesList = attributeIds.split(',');

  attributeElements.forEach((element) => {
    const valueId = element.id;
    const classes = element.classList;
    if (attributesList.includes(valueId)) {
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

const toggleAttributeSelected = (event) => {
  const attributeElement = event.currentTarget.parentNode;
  attributeElement.classList.toggle('selected');
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

function yieldToMain() {
  return new Promise((resolve) => {
    setTimeout(resolve, 0);
  });
}

const renderWithYieldToMain = async () => {
  const tasks = [
    toggleSelectedCategory,
    toggleExpandedCategories,
    toggleVisibleSelectedCategory,
    toggleVisibleAtrributes,
    toggleMappedCategories,
  ];

  while (tasks.length > 0) {
    const task = tasks.shift();
    task();
    await yieldToMain();
  }
};

const renderWithScheduler = () => {
  scheduler.postTask(toggleSelectedCategory, {priority: 'user-blocking'});
  scheduler.postTask(toggleExpandedCategories, {priority: 'user-blocking'});
  scheduler.postTask(toggleVisibleSelectedCategory);
  scheduler.postTask(toggleVisibleAtrributes);
  scheduler.postTask(toggleMappedCategories);
};

let renderPageFunc = (() => {
  if ('scheduler' in window) {
    return renderWithScheduler;
  } else {
    return renderWithYieldToMain;
  }
})();

const renderPage = () => {
  renderPageFunc();
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

  categoryNodeElements.forEach((element) => {
    addOnClick(element, () =>
      toggleNode(
        element.id,
        element.closest('.category-level').dataset.nodeDepth,
      ),
    );
  });

  attributeTitleElements.forEach((attribute) =>
    addOnClick(attribute, toggleAttributeSelected),
  );
};

const ensureCategoryGID = (categoryNodeId) => {
  if (!categoryNodeId) return;
  if (categoryNodeId.startsWith("gid://shopify/TaxonomyCategory/"))
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
  setInitialNode();
  setupListeners();
  renderPage();
};
