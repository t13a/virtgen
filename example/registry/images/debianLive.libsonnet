// Only the latest point release is under debian-cd. Older ones move to cdimage/archive.
function(version, flavor) {
  local file = 'debian-live-' + version + '-amd64-' + flavor + '.iso',
  url: 'https://cdimage.debian.org/debian-cd/' + version + '-live/amd64/iso-hybrid/' + file,
  volume: file,
  format: 'raw',
}
