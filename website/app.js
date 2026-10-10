const targets = document.querySelectorAll('.section,.launch,.workflow-grid article,.signal-list div');
const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

const revealStyle = document.createElement('style');
revealStyle.textContent = '.visible{opacity:1!important;transform:none!important}';
document.head.appendChild(revealStyle);

if ('IntersectionObserver' in window && !reduceMotion) {
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12 });

  targets.forEach(element => {
    element.style.transition = 'opacity .7s ease, transform .7s ease';
    element.style.opacity = '0';
    element.style.transform = 'translateY(18px)';
    observer.observe(element);
  });
} else {
  targets.forEach(element => element.classList.add('visible'));
}
