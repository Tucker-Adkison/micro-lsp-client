npx esbuild ../src/index.js --bundle --platform=node --outfile=dist/app.js

echo '{ "main": "dist/app.js", "output": "sea-prep.blob" }' > sea-config.json 

node --experimental-sea-config sea-config.json 

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    EXECUTABLE_NAME="lsp_client"
    cp $(command -v node) $EXECUTABLE_NAME
    
    codesign --remove-signature $EXECUTABLE_NAME
    
    chmod +w $EXECUTABLE_NAME
    
    npx postject $EXECUTABLE_NAME NODE_SEA_BLOB sea-prep.blob \
        --sentinel-fuse NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2 \
        --macho-segment-name NODE_SEA
    
    codesign --sign - $EXECUTABLE_NAME
    
else
    # Linux/Unix
    EXECUTABLE_NAME="lsp_client"
    cp $(command -v node) $EXECUTABLE_NAME
    
    chmod +w $EXECUTABLE_NAME
    
    npx postject $EXECUTABLE_NAME NODE_SEA_BLOB sea-prep.blob \
        --sentinel-fuse NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2
fi

mv lsp_client ../lsp_client
rm -rf dist
rm sea-config.json 
rm sea-prep.blob