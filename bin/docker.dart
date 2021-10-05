import 'geologger.dart' as geologger;

main() {
  geologger
      .main('run -f /var/log/access.log -d /app/GeoLite2-City.mmdb'.split(' '));
}
