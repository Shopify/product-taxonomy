import {setupAttributes, setAttribute} from './attributes.js';
import {setupSearch} from './search.js';

document.addEventListener('DOMContentLoaded', () => {
  setupAttributes();
  setupSearch(
    'attribute-search',
    'attribute-search-results',
    '../attribute_search_index.json',
    setAttribute,
    10,
    [
      {name: 'title', score: 0.5},
      {name: 'attribute.name', score: 1},
      {name: 'attribute.handle', score: 0.8},
    ],
  );
});
