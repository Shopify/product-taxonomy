import Fuse from 'https://cdn.jsdelivr.net/npm/fuse.js@7.0.0/dist/fuse.mjs';
import {q} from './util.js';
import {setAttribute} from './attributes.js';

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
            {name: 'title', score: 0.5},
            {name: 'attribute.id', score: 0.8},
          ],
        }),
    );
    return fuse;
  };
})();

const getSearchIndex = (() => {
  let searchIndex;
  return () => {
    if (searchIndex) return searchIndex;
    // intentionally local so each release has its own search index
    searchIndex = fetch('./attributes_search_index.json').then((res) => res.json());
    return searchIndex;
  };
})();

const searchDebounceMs = 200;

export const setupSearch = async () => {
  // wait for fuse/searchIndex to load before setting up listeners
  await getFuse();

  const searchInput = q('#attribute-search');
  const searchResults = q('#attribute-search-results');

  searchInput.placeholder = 'Search for attributes';

  let timeoutId;
  searchInput.addEventListener('input', (e) => {
    resetSearch();
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => {
      attributeSearch(e.target.value);
    }, searchDebounceMs);
  });
  searchInput.addEventListener('focus', () => {
    clearTimeout(timeoutId);
  });

  const handleBlur = (e) => {
    if (searchResults.contains(e.relatedTarget)) return;
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => resetSearch({clearInput: true}), 200);
  };
  searchResults.addEventListener('blur', handleBlur);
  searchInput.addEventListener('blur', handleBlur);
};

const resetSearch = ({clearInput, focusInput} = {}) => {
  if (clearInput) q('#attribute-search').value = '';
  if (focusInput) q('#attribute-search').focus();
  const searchContainer = q('#attribute-search-results');
  searchContainer.innerHTML = '';
  searchContainer.style.display = 'none';
};

async function attributeSearch(query) {
  if (!query.trim()) return;
  const searchContainer = q('#attribute-search-results');
  searchContainer.style.display = 'block';

  const fuse = await getFuse();
  const results = fuse.search(query, {limit: 5});
  if (results.length === 0) {
    const noResults = document.createElement('li');
    noResults.textContent = 'No results found';
    noResults.style.minWidth = '160px';
    searchContainer.appendChild(noResults);
    return;
  }

  results.forEach(({item}) => {
    const searchResult = document.createElement('li');
    const searchLink = document.createElement('a');

    searchLink.textContent = item.title;
    searchLink.href = item.url;
    searchLink.onclick = (e) => {
      e.preventDefault();
      setAttribute(item.attribute.id);
      resetSearch({clearInput: true, focusInput: e.detail === 0});
    };
    searchResult.appendChild(searchLink);
    searchContainer.appendChild(searchResult);
  });
}
