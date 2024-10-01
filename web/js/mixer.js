function mixColors(r1,g1,b1,r2,g2,b2,ratio) {
    let rgb1 = "rgb(" + r1 + "," + g1 + "," + b1 + ")";
    let rgb2 = "rgb(" + r2 + "," + g2 + "," + b2 + ")";
    let mix = mixbox.lerp(rgb1, rgb2, ratio);
    //console.log("Mix: " + mix);
    return mix;
}