from transformers import AutoModelForCausalLM, AutoTokenizer
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

class DialoGPTModel:
    def __init__(self):
        self.model = None
        self.tokenizer = None

    def load(self):
        logger.info("Loading DialoGPT model...")
        self.tokenizer = AutoTokenizer.from_pretrained("microsoft/DialoGPT-small")
        self.model = AutoModelForCausalLM.from_pretrained("microsoft/DialoGPT-small")
        self.model.eval()
        logger.info("DialoGPT loaded successfully.")

    def generate(self, text: str, max_length: int = 1000) -> str:
        # For a simple single-turn conversation, we just encode the user input
        input_ids = self.tokenizer.encode(text + self.tokenizer.eos_token, return_tensors='pt')

        # Generate a response from the model
        output_ids = self.model.generate(
            input_ids,
            max_length=max_length,
            pad_token_id=self.tokenizer.eos_token_id,
            do_sample=True,        # for some variation in responses
            top_k=50,              # you can tune these sampling parameters as needed
            top_p=0.95
        )

        # The model generates tokens for the entire conversation (input + response).
        # We slice off the input tokens to return only the generated response.
        response = self.tokenizer.decode(
            output_ids[:, input_ids.shape[-1]:][0],
            skip_special_tokens=True
        )
        return response
