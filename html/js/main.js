// Smooth scrolling for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Add scroll class to header for shadow effect
const header = document.querySelector('.header');
window.addEventListener('scroll', () => {
    if (window.scrollY > 0) {
        header.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.1)';
    } else {
        header.style.boxShadow = 'none';
    }
});

// Intersection Observer for fade-in animations
const observerOptions = {
    root: null,
    rootMargin: '0px',
    threshold: 0.1
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('fade-in');
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

// Observe all sections
document.querySelectorAll('section').forEach(section => {
    section.classList.add('fade-in-section');
    observer.observe(section);
});

// Add animation classes
const style = document.createElement('style');
style.textContent = `
    .fade-in-section {
        opacity: 0;
        transform: translateY(20px);
        transition: opacity 0.6s ease-out, transform 0.6s ease-out;
    }
    
    .fade-in {
        opacity: 1;
        transform: translateY(0);
    }
`;
document.head.appendChild(style); 

// Carousel functionality
function initCarousel(containerClass) {
    const container = document.querySelector(containerClass);
    if (!container) return;

    const slides = container.querySelector('.scenario-slides');
    const dots = container.querySelectorAll('.dot');
    let currentSlide = 0;
    let touchStartX = 0;
    let touchEndX = 0;

    // Set initial position
    updateSlidePosition();

    // Add touch events for mobile
    slides.addEventListener('touchstart', (e) => {
        touchStartX = e.touches[0].clientX;
    });

    slides.addEventListener('touchmove', (e) => {
        touchEndX = e.touches[0].clientX;
    });

    slides.addEventListener('touchend', () => {
        const difference = touchStartX - touchEndX;
        if (Math.abs(difference) > 50) { // Minimum swipe distance
            if (difference > 0) {
                // Swipe left
                nextSlide();
            } else {
                // Swipe right
                previousSlide();
            }
        }
    });

    // Add click events for dots
    dots.forEach((dot, index) => {
        dot.addEventListener('click', () => {
            currentSlide = index;
            updateSlidePosition();
        });
    });

    function updateSlidePosition() {
        const slideWidth = slides.clientWidth;
        slides.style.transform = `translateX(-${currentSlide * slideWidth}px)`;
        
        // Update dots
        dots.forEach((dot, index) => {
            dot.classList.toggle('active', index === currentSlide);
        });
    }

    function nextSlide() {
        currentSlide = (currentSlide + 1) % dots.length;
        updateSlidePosition();
    }

    function previousSlide() {
        currentSlide = (currentSlide - 1 + dots.length) % dots.length;
        updateSlidePosition();
    }

    // Auto advance slides
    setInterval(nextSlide, 5000);

    // Update on window resize
    window.addEventListener('resize', updateSlidePosition);
}

// Initialize carousel when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    initCarousel('.scenarios-carousel');
}); 