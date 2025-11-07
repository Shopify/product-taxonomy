import Fuse from 'https://cdn.jsdelivr.net/npm/fuse.js@7.0.0/dist/fuse.mjs';
import { q } from './util.js';

let fuseInstance = null;

const initializeSearchIndex = async (filename) => {
  const response = await fetch(filename);
  return response.json();
};

const initializeFuse = async (filename, keys) => {
  if (!fuseInstance) {
    const searchIndex = await initializeSearchIndex(filename);
    fuseInstance = new Fuse(searchIndex, {
      includeMatches: true,
      minMatchCharLength: 2,
      keys: keys,
    });
  }
  return fuseInstance;
};

const searchDebounceMs = 200;

export const setupSearch = async (inputId, resultsId, filename, resetResource, searchLimit, keys) => {
  await initializeFuse(filename, keys);

  const searchInput = q(`#${inputId}`);
  const searchResults = q(`#${resultsId}`);

  searchInput.placeholder = 'Search';

  let timeoutId;
  searchInput.addEventListener('input', (e) => {
    resetSearch({ inputId, resultsId });
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => {
      search(e.target.value, inputId, resultsId, resetResource, searchLimit);
    }, searchDebounceMs);
  });

  searchInput.addEventListener('focus', () => {
    clearTimeout(timeoutId);
  });

  const handleBlur = (e) => {
    if (searchResults.contains(e.relatedTarget)) return;
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => resetSearch({ clearInput: true, inputId, resultsId }), 200);
  };

  searchResults.addEventListener('blur', handleBlur);
  searchInput.addEventListener('blur', handleBlur);
};

const resetSearch = ({ clearInput, focusInput, inputId, resultsId } = {}) => {
  const searchInput = q(`#${inputId}`);
  const searchContainer = q(`#${resultsId}`);
  if (clearInput) searchInput.value = '';
  if (focusInput) searchInput.focus();
  searchContainer.innerHTML = '';
  searchContainer.style.display = 'none';
};

const search = async (query, inputId, resultsId, resetResource, searchLimit) => {
  if (!query.trim()) return;
  const searchContainer = q(`#${resultsId}`);
  searchContainer.style.display = 'block';

  const results = fuseInstance.search(query, { limit: searchLimit });

  if (results.length === 0) {
    const noResults = document.createElement('li');
    noResults.textContent = 'No results found';
    noResults.style.minWidth = '160px';
    searchContainer.appendChild(noResults);
    return;
  }

  results.forEach(({ item }) => {
    const searchResult = document.createElement('li');
    const searchLink = document.createElement('a');

    searchLink.textContent = item.title;
    searchLink.href = item.url;
    searchLink.onclick = (e) => {
      e.preventDefault();
      const searchInput = q(`#${inputId}`);
      searchInput.value = item.title;
      resetResource(item.searchIdentifier);
      resetSearch({ clearInput: false, focusInput: e.detail === 0, inputId, resultsId });
    };
    searchResult.appendChild(searchLink);
    searchContainer.appendChild(searchResult);
  });
};
