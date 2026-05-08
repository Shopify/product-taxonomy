import {setupAttributes, setAttribute} from './attributes.js';
import {setupSearch} from './search.js';

document.addEventListener('DOMContentLoaded', () => {
  setupAttributes();
  setupSearch(
    'attribute-search',
    'attribute-search-results',
    '../attribute_search_index.json',
    setAttribute,
    20,
    [
      {name: 'title', weight: 0.5},
      {name: 'attribute.name', weight: 1},
      {name: 'attribute.handle', weight: 0.8},
    ],
  );
});
