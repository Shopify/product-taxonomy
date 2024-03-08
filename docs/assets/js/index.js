import Fuse from "https://cdn.jsdelivr.net/npm/fuse.js@7.0.0/dist/fuse.mjs";
import categories from "./search_index.json" assert { type: "json" };

const searchDebounceMs = 200;
const nodeQueryParamKey = "categoryId";
let selectedNodes = {};
let selectedNode = null;

const getQueryParam = (param) => {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get(param);
};

const qq = (selector, context = document) =>
  Array.from(context.querySelectorAll(selector));
const q = (selector, context = document) => context.querySelector(selector);

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
  qq(".accordion-item").forEach((item) => {
    const nodeId = item.getAttribute("node_id");
    if (Object.values(selectedNodes).includes(nodeId)) {
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
  q(".secondary-container").classList.remove("active");
  if (!selectedNode) return;
  q(".secondary-container").classList.add("active");

  const documentNode = q(`.accordion-item[node_id="${selectedNode}"]`);
  const attributeIds = documentNode.getAttribute("attribute_ids");
  const attributeList = attributeIds.split(",");

  qq(".attribute-container").forEach((attribute) => {
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
  qq(".accordion-item").forEach((item) => {
    item.addEventListener("click", (e) => {
      toggleNode(
        e.target.getAttribute("node_id"),
        e.target.closest(".sibling-list").getAttribute("node_depth")
      );
    });
  });
  qq(".attribute-title").forEach((attribute) => {
    attribute.addEventListener("click", toggleAttributeSelected);
  });

  setupSearchListeners();
};

const setupSearchListeners = () => {
  const searchInput = q("#category-search");
  const searchResults = q("#category-search-results");
  let timeoutId;

  searchInput.addEventListener("input", (e) => {
    resetSearch();
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => {
      categorySearch(e.target.value);
    }, searchDebounceMs);
  });
  searchInput.addEventListener("focus", () => {
    clearTimeout(timeoutId);
  });

  const handleBlur = (e) => {
    if (searchResults.contains(e.relatedTarget)) return;
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => resetSearch({ clearInput: true }), 200);
  };

  searchResults.addEventListener("blur", handleBlur);
  searchInput.addEventListener("blur", handleBlur);
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

const resetSearch = ({ clearInput, focusInput } = {}) => {
  if (clearInput) q("#category-search").value = "";
  if (focusInput) q("#category-search").focus();
  const searchContainer = q("#category-search-results");
  searchContainer.innerHTML = "";
  searchContainer.style.display = "none";
};

let _fuse;
const getFuse = () => {
  if (_fuse) return _fuse;
  _fuse = new Fuse(categories, {
    includeMatches: true,
    minMatchCharLength: 2,
    keys: [
      { name: "title", score: 0.5 },
      { name: "category.name", score: 1 },
      { name: "category.id", score: 0.8 },
    ],
  });
  return _fuse;
};

function categorySearch(query) {
  if (!query.trim()) return;
  const searchContainer = q("#category-search-results");
  searchContainer.style.display = "block";

  const results = getFuse().search(query, { limit: 5 });
  if (results.length === 0) {
    searchContainer.textContent = "No results found";
    return;
  }

  results.forEach(({ item }) => {
    const searchResult = document.createElement("li");
    const searchLink = document.createElement("a");
    // TODO: use item.matches to highlight the matched characters
    searchLink.textContent = item.title;
    searchLink.href = item.url;
    searchLink.onclick = (e) => {
      e.preventDefault();
      selectedNodes = {};
      setNodeQueryParam(item.category.id);
      setInitialNode();
      renderPage();
      resetSearch({ clearInput: true, focusInput: e.detail === 0 });
    };
    searchResult.appendChild(searchLink);
    searchContainer.appendChild(searchResult);
  });
}

document.addEventListener("DOMContentLoaded", () => {
  setInitialNode();
  setupListeners();
  renderPage();
});
