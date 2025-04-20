// Arquivo para inicialização do jQuery na página de resultados do quiz
document.addEventListener('turbo:load', function() {
  // Verifica se estamos na página de resultados do quiz
  if (window.location.pathname.includes('quiz_results')) {
    console.log('Inicializando página de resultados do quiz');
    
    // Verifica se o jQuery está disponível
    if (typeof jQuery !== 'undefined') {
      console.log('jQuery disponível na página de resultados:', jQuery.fn.jquery);
      
      // Inicializa componentes que dependem do jQuery
      $('.card-header').each(function() {
        console.log('Processando card de resultado');
        // Qualquer inicialização específica dos cards de resultados aqui
      });
    } else {
      console.error('jQuery não está disponível na página de resultados!');
      
      // Tenta carregar o jQuery de forma síncrona
      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js';
      script.onload = function() {
        console.log('jQuery carregado manualmente com sucesso');
        window.$ = window.jQuery = jQuery;
      };
      document.head.appendChild(script);
    }
  }
}); 