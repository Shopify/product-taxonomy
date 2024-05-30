import { q, qq, getQueryParam } from "./util.js";

const nodeQueryParamKey = "categoryId";
let selectedNodes = {};
let selectedNode = null;
let cachedElements = {
  mappingElements: null,
};

const toggleExpandedCategories = () => {
  qq(".sibling-list").forEach((list) => {
    const parentId = list.dataset.parentId;
    const depth = list.dataset.nodeDepth - 1;
    if (selectedNodes[depth] === parentId) {
      list.classList.add("visible");
    } else {
      list.classList.remove("visible");
    }
  });
};

const toggleSelectedCategory = () => {
  const selectedNodeIds = Object.values(selectedNodes);
  qq(".accordion-item").forEach((item) => {
    const nodeId = item.id;
    if (selectedNodeIds.includes(nodeId)) {
      item.classList.add("selected");
    } else {
      item.classList.remove("selected");
    }
  });
};

const toggleVisibleCategory = () => {
  qq(".category-container").forEach((item) => {
    const nodeId = item.id;
    if (selectedNode === nodeId) {
      item.classList.add("visible");
    } else {
      item.classList.remove("visible");
    }
  });
};

const toggleSecondaryContainer = () => {
  const secondaryContainer = q(".secondary-container-visibility");

  if (selectedNode) {
    secondaryContainer.classList.add("visible");
  } else {
    secondaryContainer.classList.remove("visible");
  }
};

const toggleVisibleAtrributes = () => {
  if (!selectedNode) return;

  const attributeElements = qq(".attribute-values");
  const documentNode = q(`.accordion-item[id="${selectedNode}"]`);

  if (!documentNode) {
    return attributeElements.forEach((element) => element.classList.remove("visible"));
  }

  const attributeIds = documentNode.dataset.attributeIds;
  const attributesList = attributeIds.split(",");

  attributeElements.forEach((element) => {
    const valueId = element.id;
    if (attributesList.includes(valueId)) {
      element.classList.add("visible");
    } else {
      element.classList.remove("visible");
    }
  });
};

const readMappingElements = () => {
  if (cachedElements.mappingElements) {
    return cachedElements.mappingElements;
  }

  return cachedElements.mappingElements = qq(".mapped-category");
};

const toggleMappedCategories = () => {
  const mappingElements = readMappingElements();

  mappingElements.forEach((element) => {
    const valueId = element.id;
    if (selectedNode === valueId) {
      element.classList.add("visible");
    } else {
      element.classList.remove("visible");
    }
  });
};

const toggleAttributeSelected = (event) => {
  const attributeElement = event.currentTarget.parentNode;
  attributeElement.classList.toggle("selected");
};

const setNodeQueryParam = (nodeId) => {
  const url = new URL(window.location);
  if (nodeId != null) {
    url.searchParams.set(nodeQueryParamKey, nodeId);
  } else {
    url.searchParams.delete(nodeQueryParamKey);
  }
  window.history.pushState({}, "", url);
};

const renderWithManualPriority = () => {
  toggleSelectedCategory();
  toggleExpandedCategories();
  toggleVisibleCategory();


  setTimeout(() => {
    toggleVisibleAtrributes();
    toggleMappedCategories();
  }, 0);
};

function yieldToMain () {
  return new Promise(resolve => {
    setTimeout(resolve, 0);
  });
}

const renderWithYieldToMain = async () => {
  const tasks = [
    toggleSelectedCategory,
    toggleExpandedCategories,
    toggleVisibleCategory,
    toggleVisibleAtrributes,
    toggleMappedCategories,
  ];

  while (tasks.length > 0) {
    const task = tasks.shift();
    task();
    await yieldToMain();
  };
};

const renderWithScheduler = () => {
  scheduler.postTask(toggleSelectedCategory, {priority: 'user-blocking'});
  scheduler.postTask(toggleExpandedCategories, {priority: 'user-blocking'});
  scheduler.postTask(toggleVisibleCategory);
  scheduler.postTask(toggleVisibleAtrributes);
  scheduler.postTask(toggleMappedCategories);
};

const renderWithoutPriority = () => {
  toggleSelectedCategory();
  toggleExpandedCategories();
  toggleVisibleCategory();
  toggleVisibleAtrributes();
  toggleMappedCategories();
};

const renderPage = () => {
  performance.mark("start");
  renderWithYieldToMain();
  performance.mark("end");
  console.log(performance.measure("renderPage", "start", "end"));
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
  target.addEventListener("click", handler);
  target.addEventListener("keypress", (e) => {
    if (e.key === "Enter" || e.key === " ") {
      target.dispatchEvent(new Event("click"));
    }
  });
};

const setupListeners = () => {
  qq(".accordion-item").forEach((item) => {
    addOnClick(item, () =>
      toggleNode(
        item.id,
        item.closest(".sibling-list").dataset.nodeDepth
      )
    );
  });
  qq(".attribute-title").forEach((attribute) =>
    addOnClick(attribute, toggleAttributeSelected)
  );
};

const setInitialNode = () => {
  const initialNode = getQueryParam(nodeQueryParamKey);
  if (!initialNode) return;

  const documentNode = q(`.accordion-item[id="${initialNode}"]`);
  if (!documentNode) return;

  const ancestors = documentNode.dataset.ancestorIds
    ? documentNode.dataset.ancestorIds.split(",")
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
