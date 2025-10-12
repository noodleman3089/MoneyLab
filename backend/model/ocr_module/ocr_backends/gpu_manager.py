"""
GPU Manager for handling GPU detection and configuration
"""


class GPUManager:
    """Manages GPU detection and configuration"""

    @staticmethod
    def is_gpu_available() -> bool:
        """Check if CUDA GPU support is available"""
        try:
            import paddle
            if paddle.device.is_compiled_with_cuda():
                gpu_count = paddle.device.cuda.device_count()
                if gpu_count > 0:
                    print(f"GPU support detected: {gpu_count} CUDA device(s) available")
                    return True
                else:
                    print("CUDA is available but no GPU devices found")
                    return False
            else:
                print("PaddlePaddle not compiled with CUDA support")
                return False
        except Exception as e:
            print(f"GPU check failed: {e}")
            return False

    @staticmethod
    def configure_paddle_device(use_gpu: bool) -> str:
        """Configure PaddlePaddle device"""
        if use_gpu and GPUManager.is_gpu_available():
            try:
                import paddle
                paddle.device.set_device('gpu:0')
                print("Using GPU for OCR processing")
                return 'gpu'
            except Exception as e:
                print(f"Failed to set GPU device: {e}")
                print("Falling back to CPU")
                return 'cpu'
        else:
            print("Using CPU for OCR processing")
            return 'cpu'
