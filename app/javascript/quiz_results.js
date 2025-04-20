// Arquivo para inicialização do jQuery na página de resultados do quiz
document.addEventListener('turbo:load', function() {
  // Verifica se estamos na página de resultados do quiz
  if (window.location.pathname.includes('quiz_results')) {
    console.log('Inicializando página de resultados do quiz');
    
    // Verifica se o jQuery está disponível de forma mais segura
    if (typeof jQuery !== 'undefined' && jQuery) {
      console.log('jQuery disponível na página de resultados');
      
      // Inicializa componentes que dependem do jQuery
      try {
        jQuery('.card-header').each(function() {
          console.log('Processando card de resultado');
          // Qualquer inicialização específica dos cards de resultados aqui
        });
      } catch (error) {
        console.error('Erro ao processar com jQuery:', error);
      }
    } else {
      console.error('jQuery não está disponível na página de resultados!');
      
      // Tenta carregar o jQuery de forma síncrona
      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js';
      script.onload = function() {
        console.log('jQuery carregado manualmente com sucesso');
        window.$ = window.jQuery = jQuery;
        
        // Tenta inicializar os componentes novamente após o carregamento
        try {
          jQuery('.card-header').each(function() {
            console.log('Processando card de resultado após carregamento manual');
          });
        } catch (error) {
          console.error('Erro ao processar com jQuery após carregamento manual:', error);
        }
      };
      document.head.appendChild(script);
    }
  }
}); 