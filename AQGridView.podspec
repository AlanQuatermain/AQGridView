pod do |s|
  s.name     = 'AQGridView'
  s.version  = '1.4'
  s.license  = 'BSD'
  s.summary  = 'A grid view for iPhone/iPad, designed to look similar to NSCollectionView.'
  s.homepage = 'https://github.com/AlanQuatermain/AQGridView'
  s.author   = { 'Alan Quatermain' => 'jimdovey@mac.com' }
  s.source   = { :git => 'https://github.com/gabrielrinaldi/AQGridView.git', :commit => 'b4d48103f08caa030e029c147d37aa31bd6048a7' }
  s.platform = :ios
  s.requires_arc = true
  s.source_files = 'Classes'
  s.resources = "Resources/*.png"

  s.framework = 'QuartzCore'
end
