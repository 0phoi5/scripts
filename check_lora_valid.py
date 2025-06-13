from safetensors.torch import load_file

# Replace this with your actual path if different
path = "vickixbourneonedotfive.safetensors"

weights = load_file(path)
lora_keys = [k for k in weights.keys() if k.startswith("lora")]

print("LoRA keys found:", lora_keys[:5])
print("Total LoRA keys:", len(lora_keys))
