int main(){return 0;}
EOF && gcc test.c -o test && strip --strip-unneeded test && readelf -S test | grep build-id || true
