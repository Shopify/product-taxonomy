import Fuse from "https://cdn.jsdelivr.net/npm/fuse.js@7.0.0/dist/fuse.mjs";
import categories from "./search_index.json" assert { type: "json" };

let selectedNodes = {};
const nodeQueryParamKey = "categoryId";
let selectedNode = null;

const getQueryParam = (param) => {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get(param);
};

const toggleExpandedCategories = () => {
  document.querySelectorAll(".sibling-list").forEach((list) => {
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
  document.querySelectorAll(".accordion-item").forEach((item) => {
    const nodeId = item.getAttribute("node_id");
    if (Object.values(selectedNodes).includes(nodeId)) {
      item.classList.add("selected");
    } else {
      item.classList.remove("selected");
    }
  });
};

const toggleVisibleCategory = () => {
  document.querySelectorAll(".category-container").forEach((item) => {
    const nodeId = item.getAttribute("id");
    if (selectedNode === nodeId) {
      item.classList.add("active");
    } else {
      item.classList.remove("active");
    }
  });
};

const toggleVisibleAttributes = () => {
  document.querySelector(".secondary-container").classList.remove("active");
  if (!selectedNode) return;
  document.querySelector(".secondary-container").classList.add("active");

  const documentNode = document.querySelector(
    `.accordion-item[node_id="${selectedNode}"]`
  );
  const attributeIds = documentNode.getAttribute("attribute_ids");
  const attributeList = attributeIds.split(",");

  document.querySelectorAll(".attribute-container").forEach((attribute) => {
    const attributeId = attribute.getAttribute("id");
    if (attributeList.includes(attributeId)) {
      attribute.classList.add("active");
    } else {
      attribute.classList.remove("active");
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

const renderPage = () => {
  toggleExpandedCategories();
  toggleSelectedCategory();
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

const setupListeners = () => {
  document.querySelectorAll(".accordion-item").forEach((item) => {
    item.addEventListener("click", (e) => {
      toggleNode(
        e.target.getAttribute("node_id"),
        e.target.closest(".sibling-list").getAttribute("node_depth")
      );
    });
  });
  document.querySelectorAll(".attribute-title").forEach((attribute) => {
    attribute.addEventListener("click", toggleAttributeSelected);
  });
};

const setInitialNode = () => {
  const initialNode = getQueryParam(nodeQueryParamKey);
  const documentNode = document.querySelector(
    `.accordion-item[node_id="${initialNode}"]`
  );
  if (!documentNode) return;

  const ancestors = documentNode.getAttribute("ancestor_ids")
    ? documentNode.getAttribute("ancestor_ids").split(",")
    : [];
  const depth = ancestors.length;

  if (initialNode) {
    ancestors.forEach((ancestor, index) => {
      selectedNodes[depth - index - 1] = ancestor;
    });
    selectedNodes[depth] = initialNode;
    selectedNode = initialNode;
  }
};

const fuse = new Fuse(categories, {
  includeMatches: true,
  minMatchCharLength: 2,
  keys: [
    { name: "title", score: 0.5 },
    { name: "category.name", score: 1 },
    { name: "category.id", score: 0.8 },
  ],
});

export function categorySearch(query) {
  const searchInput = document.getElementById("category-search");
  let ul = document.getElementById("category-search-results");
  ul.innerHTML = "";

  const results = fuse.search(query, { limit: 5 });
  results.forEach(({ item }) => {
    let li = document.createElement("li");
    let elemlink = document.createElement("a");
    // TODO: use item.matches to highlight the matched characters
    elemlink.innerHTML = item.title;
    elemlink.setAttribute("href", item.url);
    elemlink.onclick = (e) => {
      e.preventDefault();
      selectedNodes = {};
      setNodeQueryParam(item.category.id);
      setInitialNode();
      renderPage();
      ul.innerHTML = "";
      searchInput.value = "";
    };
    li.appendChild(elemlink);
    ul.appendChild(li);
  });
}

document.addEventListener("DOMContentLoaded", () => {
  setInitialNode();
  setupListeners();
  renderPage();
});
