function openModal(imageSrc, caption) {
  const modal = document.getElementById("imageModal");
  const modalImage = document.getElementById("modalImage");
  const modalCaption = document.getElementById("modalCaption");
  const modalContent = modal.querySelector(".modal-content");

  const existingSpinner = modal.querySelector(".loading-spinner");
  if (existingSpinner) {
    existingSpinner.remove();
  }

  const spinner = document.createElement("div");
  spinner.className = "loading-spinner";
  modalContent.appendChild(spinner);

  modalImage.style.opacity = "0";
  modalImage.style.display = "none";

  modal.classList.remove("hidden");
  document.body.style.overflow = "hidden";
  modalCaption.textContent = caption;

  const img = new Image();
  img.onload = function () {
    spinner.remove();

    modalImage.src = imageSrc;
    modalImage.alt = caption;

    // Set image dimensions: height 640px, width proportional
    modalImage.style.height = "640px";
    modalImage.style.width = "auto";

    modalImage.style.display = "block";
    modalImage.style.opacity = "1";
    modalImage.style.animation = "scaleIn 0.3s ease-out";
  };

  img.onerror = function () {
    spinner.remove();
    modalCaption.textContent = "Error loading image: " + caption;
  };

  img.src = imageSrc;
}

function closeModal(event) {
  if (event && event.target.id === "modalImage") {
    return;
  }

  const modal = document.getElementById("imageModal");
  modal.classList.add("hidden");
  document.body.style.overflow = "auto";
}

document.addEventListener("keydown", function (event) {
  if (event.key === "Escape") {
    closeModal();
  }
});

document.addEventListener("DOMContentLoaded", () => {
  const filterButtons = document.querySelectorAll(".filter-btn");
  const projectCards = document.querySelectorAll(".project-card");

  const colorConfig = {
    "Reinforcement Learning": ["bg-yellow-200", "text-yellow-800"],
    "Computer Vision": ["bg-blue-200", "text-blue-800"],
    Misc: ["bg-gray-200", "text-gray-800"],
    all: ["bg-gray-200", "text-gray-800"],
  };

  const selectedColor = ["bg-red-800", "text-white"];

  function resetButtonColors() {
    filterButtons.forEach((btn) => {
      const filter = btn.dataset.filter;
      btn.classList.remove(...selectedColor);
      if (colorConfig[filter]) {
        btn.classList.add(...colorConfig[filter]);
      }
    });
  }

  filterButtons.forEach((button) => {
    button.addEventListener("click", () => {
      const filter = button.dataset.filter;

      resetButtonColors();
      button.classList.remove(...(colorConfig[filter] || []));
      button.classList.add(...selectedColor);

      projectCards.forEach((card, index) => {
        const tags = card.dataset.tags.split(",");
        const shouldShow = filter === "all" || tags.includes(filter);

        if (shouldShow) {
          card.classList.remove("fade-out");
          card.classList.add("fade-in");
          card.style.display = "block";
          card.style.animationDelay = `${index * 0.1}s`;


        } else {
          card.classList.remove("fade-in");
          card.classList.add("fade-out");

          setTimeout(() => {
            if (card.classList.contains("fade-out")) {
              card.style.display = "none";
            }
          }, 300);
        }
      });
    });
  });

  const initialFilter = document.querySelector(
    '.filter-btn[data-filter="all"]'
  );
  initialFilter.classList.remove(...colorConfig["all"]);
  initialFilter.classList.add(...selectedColor);
});
