// Reference media stay on their publishers' servers; never used as model textures.
const park = 'https://www.kechuangfuwu.com/';
const photo = (file) => park + 'ueditor/fileupload/file/' + file;
const bridgeSource = park + 'vue/news?id=7526';
const aerial = 'https://www.beijing.gov.cn/renwen/bjgk/cpgk/cpfg/202304/W020230403544690157686.jpg';
const aerialSource = 'https://www.beijing.gov.cn/renwen/bjgk/cpgk/cpfg/202304/t20230403_2965742.html';
const centerDetail = 'https://www.sohu.com/a/358608273_100004382';
const sohuPhoto = 'https://5b0988e595225.cdn.sohucs.com/images/20191205/';
const inspection = 'https://www.szgcyjy.com/menu143/newsDetail/14766.html';
const inspectionPhoto = 'https://file.bmrb.com.cn/file/upload/2023/01/28/';
export const references = {
  center: [
    ['Stone grid, recessed glass and central landscape', 'Detail photograph · 2019 publication', sohuPhoto+'4b8941fb89cd489cb8076f4f03829914.jpeg', centerDetail],
    ['Courtyard-side glazing, transoms and planted interior edge', 'Detail photograph · 2019 publication', sohuPhoto+'8d5162cd9fba47eeae75c16b1320404e.jpeg', centerDetail],
    ['Axial street elevation', 'Photograph', photo('20240726/1721961738519014567.jpg'), park+'vue/parkService/project?id=31'],
    ['Campus from above', 'Design rendering', photo('20240725/1721893738640071636.png'), park+'vue/parkService/project?id=31'],
    ['Building heights and courtyard roofs', 'Annotated design rendering', photo('20190821/1566354187609093039.jpg'), park+'vue/parkService/project?id=31'],
    ['Group layout, opposite oblique view', 'Design diagram', photo('20190821/1566353869691079929.jpg'), park+'vue/parkService/project?id=31'],
  ],
  vision: [
    ['Roof-edge planting and layered amber curtain walls', 'Detail photograph · park operator', photo('20240725/1721893131158088336.jpg'), park+'vue/parkService/project?id=36'],
    ['Tower glazing grid and hotel arrival canopy', 'Ground-level photograph · park operator', photo('20240725/1721890845348050943.jpg'), park+'vue/parkService/project?id=36'],
    ['Entrance court and orange facade strips', 'Photograph', photo('20240725/1721877653174082537.jpg'), park+'vue/parkService/project?id=36'],
    ['Taller offices behind the creative buildings', 'Photograph', photo('20240725/1721877554142081908.jpg'), park+'vue/parkService/project?id=36'],
    ['Connected footprints and roof gardens', 'Axonometric diagram', photo('20240725/1721878090189018180.png'), park+'vue/parkService/project?id=36'],
    ['Six-building composition', 'Design diagram', photo('20190821/1566375938137062237.jpg'), park+'vue/parkService/project?id=36'],
  ],
  'east-bridge': [
    ['Low riverbank view: lattice, edge girder and V-piers', 'Visit Beijing · SIPA photograph (rights retained)', 'https://r1.visitbeijing.com.cn/vbj-s/2017/1225/20171225051108793.jpg', 'https://s.visitbeijing.com.cn/gallery/7172'],
    ['Wave profile from the riverbank', 'Photograph', photo('20220713/1657702803678022077.png'), bridgeSource],
    ['Inside the pedestrian lattice', 'Photograph', photo('20220713/1657702803895058089.png'), bridgeSource],
    ['Aerial: open carriageway and riverside context', 'Government photograph', aerial, aerialSource],
  ],
  'arch-bridge': [
    ['Walkway paving, horizontal rails and arch panel joints', 'Municipal engineering inspection · 2023', inspectionPhoto+'1674887187558.jpg', inspection],
    ['Riverbank inspection view: rib seams and dark deck fascia', 'Municipal engineering inspection · 2023', inspectionPhoto+'1674887088490.jpg', inspection],
    ['Arch thickness and hanger rhythm', 'Photograph', photo('20220713/1657702803493014474.png'), bridgeSource],
    ['Approach at night: inward-leaning ribs', 'Photograph', photo('20220713/1657702803546035447.png'), bridgeSource],
    ['Aerial: arch crossing in the background', 'Government photograph', aerial, aerialSource],
  ],
};
