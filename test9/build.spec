Executable --test prog prog.c

Generate config2.h generator.py dummy.dat {
	run $PYTHON $script $inputs $target
}

#PublishBin --script generator.py

Executable --test prog2 prog2.c
