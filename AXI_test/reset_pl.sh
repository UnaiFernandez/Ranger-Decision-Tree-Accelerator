devmem 0xf8000240 32 0xf #Raise reset
sleep 1
devmem 0xf8000240 32 0x0 #Lower reset
