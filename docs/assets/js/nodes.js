import { q, qq, getQueryParam } from "./util.js";

const nodeQueryParamKey = "categoryId";
let selectedNodes = {};
let selectedNode = null;

function clearSelectedNodeIdFromTitle() {
  qq(".sibling-list-title").forEach(
    (element) => (element.firstElementChild.innerHTML = "")
  );
}

const renderSelectedNodeIdToTitle = () => {
  if (!selectedNodes) return;

  const [lastSelectedNodeKey, ..._] = Object.keys(selectedNodes).reverse();
  const lastSelectedNode = selectedNodes[lastSelectedNodeKey];

  clearSelectedNodeIdFromTitle();

  qq(".selected").forEach((element) => {
    const elementNodeId = element.getAttribute("node_id");
    if (elementNodeId === lastSelectedNode) {
      const siblingListTitleElement =
        element.closest(".sibling-list").firstElementChild;
      siblingListTitleElement.firstElementChild.insertAdjacentText(
        "afterbegin",
        lastSelectedNode
      );
    }
  });
};

const toggleExpandedCategories = () => {
  qq(".sibling-list").forEach((list) => {
    const parentId = list.getAttribute("parent_id");
    const depth = list.getAttribute("node_depth") - 1;
    if (selectedNodes[depth] === parentId) {
      list.classList.add("expanded");
    } else {
      list.classList.remove("expanded");
    }
  });
};

const toggleSelectedCategory = () => {
  const selectedNodeIds = Object.values(selectedNodes);
  qq(".accordion-item").forEach((item) => {
    const nodeId = item.getAttribute("node_id");
    if (selectedNodeIds.includes(nodeId)) {
      item.classList.add("selected");
    } else {
      item.classList.remove("selected");
    }
  });
};

const toggleVisibleCategory = () => {
  qq(".category-container").forEach((item) => {
    const nodeId = item.getAttribute("id");
    if (selectedNode === nodeId) {
      item.classList.add("active");
    } else {
      item.classList.remove("active");
    }
  });
};

const toggleVisibleAttributes = () => {
  attributeSectionTitleVisibility.remove();
  let attributeSectionTitleVisible = false;

  if (!selectedNode) return;

  const documentNode = q(`.accordion-item[node_id="${selectedNode}"]`);
  const attributeIds = documentNode.getAttribute("attribute_ids");
  const attributeList = attributeIds.split(",");

  qq(".attribute-visibility").forEach((attribute) => {
    const attributeId = attribute.getAttribute("id");
    if (attributeList.includes(attributeId)) {
      attributeSectionTitleVisible = true;
      attribute.classList.add("attribute-active");
    } else {
      attribute.classList.remove("attribute-active");
    }
  });

  if (attributeSectionTitleVisible) {
    attributeSectionTitleVisibility.set();
  }

  qq(".mapped-category-container").forEach((mappedCategory) => {
    const categoryNodeId = mappedCategory.getAttribute("category_id");
    if (selectedNode === categoryNodeId) {
      mappedCategory.classList.add("active");
    } else {
      mappedCategory.classList.remove("active");
    }
  });
};

const attributeSectionTitleVisibility = {
  set: () => qq(".attribute-section-title").forEach(element => element.classList.add("visible")),
  remove: () => qq(".attribute-section-title").forEach(element => element.classList.remove("visible")),
};

// const toggleAttributeSelected = (event) => {
//   const attributeElement = event.currentTarget.parentNode;
//   attributeElement.classList.toggle("selected");
// };

const setNodeQueryParam = (nodeId) => {
  const url = new URL(window.location);
  if (nodeId != null) {
    url.searchParams.set(nodeQueryParamKey, nodeId);
  } else {
    url.searchParams.delete(nodeQueryParamKey);
  }
  window.history.pushState({}, "", url);
};

const renderPage = () => {
  toggleExpandedCategories();
  toggleSelectedCategory();
  renderSelectedNodeIdToTitle();
  toggleVisibleAttributes();
  toggleVisibleCategory();
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
        item.getAttribute("node_id"),
        item.closest(".sibling-list").getAttribute("node_depth")
      )
    );
  });
};

const setInitialNode = () => {
  const initialNode = getQueryParam(nodeQueryParamKey);
  if (!initialNode) return;

  const documentNode = q(`.accordion-item[node_id="${initialNode}"]`);
  if (!documentNode) return;

  const ancestors = documentNode.getAttribute("ancestor_ids")
    ? documentNode.getAttribute("ancestor_ids").split(",")
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
