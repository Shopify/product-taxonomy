import Fuse from "https://cdn.jsdelivr.net/npm/fuse.js@7.0.0/dist/fuse.mjs";
import { q } from "./util.js";
import { resetToCategory } from "./nodes.js";

const getFuse = (() => {
  let fuse;
  return () => {
    if (fuse) return fuse;
    fuse = getSearchIndex().then(
      (searchIndex) =>
        new Fuse(searchIndex, {
          includeMatches: true,
          minMatchCharLength: 2,
          keys: [
            { name: "title", score: 0.5 },
            { name: "category.name", score: 1 },
            { name: "category.id", score: 0.8 },
          ],
        })
    );
    return fuse;
  };
})();

const getSearchIndex = (() => {
  let searchIndex;
  return () => {
    if (searchIndex) return searchIndex;
    searchIndex = fetch("/assets/js/search_index.json").then((res) =>
      res.json()
    );
    return searchIndex;
  };
})();

const searchDebounceMs = 200;

export const setupSearch = async () => {
  // wait for fuse/searchIndex to load before setting up listeners
  await getFuse();

  const searchInput = q("#category-search");
  const searchResults = q("#category-search-results");

  searchInput.placeholder = "Search for categories…";

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

const resetSearch = ({ clearInput, focusInput } = {}) => {
  if (clearInput) q("#category-search").value = "";
  if (focusInput) q("#category-search").focus();
  const searchContainer = q("#category-search-results");
  searchContainer.innerHTML = "";
  searchContainer.style.display = "none";
};

async function categorySearch(query) {
  if (!query.trim()) return;
  const searchContainer = q("#category-search-results");
  searchContainer.style.display = "block";

  const fuse = await getFuse();
  const results = fuse.search(query, { limit: 5 });
  if (results.length === 0) {
    const noResults = document.createElement("li");
    noResults.textContent = "No results found";
    noResults.style.minWidth = "160px";
    searchContainer.appendChild(noResults);
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
      resetToCategory(item.category.id);
      resetSearch({ clearInput: true, focusInput: e.detail === 0 });
    };
    searchResult.appendChild(searchLink);
    searchContainer.appendChild(searchResult);
  });
}
