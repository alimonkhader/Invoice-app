// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "./purchases_charts"


document.addEventListener("turbo:load", () => {
  const addButton = document.getElementById("add-item");
  const itemsDiv = document.getElementById("items");
  const totalSpan = document.getElementById("total");
  const scanPriceInput = document.getElementById("scan-price-input");
  let activeItemRow = null;

  if (!itemsDiv) return;

  // Add Item button
  if (addButton) {
    addButton.addEventListener("click", (e) => {
      e.preventDefault();

      const index = Date.now();

      const template = `
        <div class="item">
          <input type="text" name="invoice[invoice_items_attributes][${index}][name]" placeholder="Item name">
          <input type="number" name="invoice[invoice_items_attributes][${index}][quantity]" placeholder="Qty" class="qty" min="0" step="1">
          <input type="number" name="invoice[invoice_items_attributes][${index}][price]" placeholder="Price" class="price" min="0" step="0.01">
        </div>
      `;

      itemsDiv.insertAdjacentHTML("beforeend", template);
      activeItemRow = itemsDiv.querySelector(".item:last-child");
      calculateTotal();
    });
  }

  function getTargetRow() {
    if (activeItemRow && document.body.contains(activeItemRow)) {
      return activeItemRow;
    }

    return itemsDiv.querySelector(".item:last-child");
  }

  function applyScannedPrice(rawValue) {
    const normalized = String(rawValue).replace(/[^\d.]/g, "");
    const scannedPrice = parseFloat(normalized);
    if (!Number.isFinite(scannedPrice) || scannedPrice <= 0) return false;

    const row = getTargetRow();
    if (!row) return false;

    const priceInput = row.querySelector(".price");
    if (!priceInput) return false;

    priceInput.value = scannedPrice.toFixed(2);
    priceInput.dispatchEvent(new Event("input", { bubbles: true }));
    calculateTotal();

    const qtyInput = row.querySelector(".qty");
    if (qtyInput) qtyInput.focus();

    return true;
  }

  // Calculate total
  function calculateTotal() {
    let total = 0;

    document.querySelectorAll(".item").forEach((row) => {
      const qty = parseFloat(row.querySelector(".qty")?.value) || 0;
      const price = parseFloat(row.querySelector(".price")?.value) || 0;

      total += qty * price;
    });

    if (totalSpan) {
      totalSpan.innerText = total.toFixed(2);
    }
  }

  // Listen to input changes
  document.addEventListener("input", (e) => {
    if (
      e.target.classList.contains("qty") ||
      e.target.classList.contains("price")
    ) {
      calculateTotal();
    }
  });

  document.addEventListener("focusin", (e) => {
    const row = e.target.closest(".item");
    if (row) activeItemRow = row;
  });

  if (scanPriceInput) {
    scanPriceInput.addEventListener("keydown", (e) => {
      if (e.key !== "Enter") return;

      e.preventDefault();
      const didApply = applyScannedPrice(scanPriceInput.value);
      scanPriceInput.value = "";
      if (didApply) scanPriceInput.blur();
    });
  }

  calculateTotal();
});
