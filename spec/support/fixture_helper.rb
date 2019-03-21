def fixture_path(path = '')
  root = File.expand_path('../../fixtures', __FILE__)
  File.join(root, path)
end
