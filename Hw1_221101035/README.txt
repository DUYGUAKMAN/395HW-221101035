Burada iki tane dosya var. Biri calculator.l adlı lex dosyası, diğeri ise calculator.y dosyası.
Flex ve bison kullanarak flex -o calculator.l yazıyoruz. Daha sonra da bison -d calculator.y yazıyoruz.
Daha sonra oluşan dosyalar üzerine gcc lex.yy.c y.tab.c -o calculator -lm yazıyoruz. Bu bize calculator adında bir file veriyor.
./calculator yazarak ise hesap makinesini kullanabiliyoruz.
