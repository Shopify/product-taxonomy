const selectedNodes = {};
const nodeQueryParamKey = 'categoryId';
let selectedNode = null;

const getQueryParam = (param) => {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get(param);
}

const toggleExpanded = () => {
  document.querySelectorAll(".sibling-list").forEach(list => {
    const parentId = list.getAttribute('parent_id');
    const depth = list.getAttribute('node_depth') - 1;
    if (selectedNodes[depth] === parentId) {
      list.classList.add("expanded");
    } else {
      list.classList.remove("expanded");
    }
  });
};

const toggleSelected = () => {
  document.querySelectorAll(".accordion-item").forEach(item => {
    const nodeId = item.getAttribute('node_id');
    if (Object.values(selectedNodes).includes(nodeId)) {
      item.classList.add("selected");
    } else {
      item.classList.remove("selected");
    }
  });
}

const setNodeQueryParam = (nodeId) => {
  const url = new URL(window.location);
  if (nodeId != null) {
    url.searchParams.set(nodeQueryParamKey, nodeId);
  } else {
    url.searchParams.delete(nodeQueryParamKey);
  }
  window.history.pushState({}, '', url);
}

const toggleNode = (event) => {
  const nodeId = event.target.getAttribute('node_id');
  const depth = event.target.closest(".sibling-list").getAttribute('node_depth');
  if (selectedNodes[depth] === nodeId) {
    delete selectedNodes[depth];
    selectedNode = selectedNodes[depth - 1];
  } else {
    selectedNodes[depth] = nodeId;
    selectedNode = nodeId;
  }
  Object.keys(selectedNodes).forEach(key => {
    if (key > depth) {
      delete selectedNodes[key];
    }
  });

  setNodeQueryParam(selectedNode);
  toggleExpanded();
  toggleSelected();
}

const setupListeners = () => {
  document.querySelectorAll('.accordion-item').forEach(item => {
    item.addEventListener('click', toggleNode);
  });
};

const setInitialNode = () => {
  const initialNode = getQueryParam(nodeQueryParamKey);
  const documentNode = document.querySelector(`.accordion-item[node_id="${initialNode}"]`);
  if(!documentNode) return;

  const ancestors = documentNode.getAttribute('ancestor_ids') ? documentNode.getAttribute('ancestor_ids').split(',') : [];
  const depth = ancestors.length;

  if (initialNode) {
    ancestors.forEach((ancestor, index) => {
      selectedNodes[depth - index - 1] = ancestor;
    });
    selectedNodes[depth] = initialNode;
    selectedNode = initialNode;
  }
}


document.addEventListener('DOMContentLoaded', () => {
  setInitialNode();
  setupListeners();
  toggleExpanded();
  toggleSelected();
});
