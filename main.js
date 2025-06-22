console.log("NailColorizer Lite UI Loaded!");

let selectedColor = "#FF69B4";
let apiUrl = "";

async function fetchApiUrl() {
  const response = await fetch('api-info.json');
  const data = await response.json();
  apiUrl = data.api_url;
}

function selectColor(hex) {
  document.getElementById('selectedColor').value = hex;
}

async function submitForm() {
  if (!apiUrl) await fetchApiUrl();
  const fileInput = document.getElementById('fileInput');
  const color = document.getElementById('selectedColor').value;
  const preview = document.getElementById('preview');

  if (!fileInput.files.length) {
    alert('Please upload or take a photo.');
    return;
  }

  const formData = new FormData();
  formData.append('file', fileInput.files[0]);
  formData.append('color', color);

  const response = await fetch(apiUrl, {
    method: 'POST',
    body: formData
  });

  if (response.ok) {
    const blob = await response.blob();
    preview.src = URL.createObjectURL(blob);
    preview.hidden = false;
  } else {
    alert('Failed to process image.');
  }
}

fetchApiUrl();
