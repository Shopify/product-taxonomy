import {setupNodes, resetToCategory} from './nodes.js';
import {setupSearch} from './search.js';

document.addEventListener('DOMContentLoaded', () => {
  setupNodes();
  setupSearch('search', 'search-results', './search_index.json', resetToCategory, 5, [
    {name: 'title', score: 0.5},
    {name: 'category.name', score: 1},
    {name: 'category.id', score: 0.8},
  ]);
});
