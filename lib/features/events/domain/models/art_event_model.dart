class GalleryImageItem {
  final String title;
  final String imageUrl;
  final String caption;

  const GalleryImageItem({
    required this.title,
    required this.imageUrl,
    this.caption = 'Event highlight',
  });
}

class EventPhotoGallery {
  final String title;
  final String? subtitle;
  final int photoCount;
  final String date;
  final String imageUrl;
  final List<GalleryImageItem> images;

  const EventPhotoGallery({
    required this.title,
    this.subtitle,
    required this.photoCount,
    required this.date,
    required this.imageUrl,
    this.images = const [],
  });
}

class ArtEventModel {
  final String id;
  final String title;
  final String category;
  final String price;
  final String description;
  final String requirements;
  final String dateTime;
  final String formattedDate;
  final String timeRange;
  final String location;
  final String? locationCity;
  final int attendeesCount;
  final int maxAttendees;
  final String organizer;
  final String? organizerEmail;
  final List<String> tags;
  final String? imageUrl;
  final List<EventPhotoGallery> galleries;

  const ArtEventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.description,
    this.requirements = 'Open to all art enthusiasts and creators.',
    required this.dateTime,
    this.formattedDate = 'Thursday, 4 September 2025',
    this.timeRange = '10:00 AM - 02:00 AM',
    required this.location,
    this.locationCity,
    required this.attendeesCount,
    required this.maxAttendees,
    required this.organizer,
    this.organizerEmail,
    required this.tags,
    this.imageUrl,
    this.galleries = const [],
  });

  int get spotsRemaining => (maxAttendees - attendeesCount).clamp(0, maxAttendees);

  static const List<String> categories = [
    'All Categories',
    'Art Exhibition',
    'Gallery Opening',
    'Art Workshop',
    'Artist Talk',
    'Art Fair',
    'Sculpture Installation',
    'Photography Exhibition',
    'Cultural Festival',
    'Art Competition',
    'Community Art Project',
  ];

  static List<ArtEventModel> get mockEvents => const [
        ArtEventModel(
          id: 'demo-art-event-10',
          title: 'Demo Art Event 10',
          category: 'Art Exhibition',
          price: '20.00 AED',
          description: 'Experience art at Demo Event 10 with creators and live showcases.',
          requirements: 'Valid ticket required at the entrance.',
          dateTime: 'Sat, 6 Sep 2025 at 01:44 PM',
          formattedDate: 'Saturday, 6 September 2025',
          timeRange: '01:44 PM - 04:44 PM',
          location: 'City Art Center',
          locationCity: 'Berlin',
          attendeesCount: 0,
          maxAttendees: 110,
          organizer: 'Artist 10',
          organizerEmail: 'artist10@dubaiart.ae',
          tags: ['art', 'demo'],
          galleries: [
            EventPhotoGallery(
              title: 'Event Gallery: Demo Art Event 2',
              subtitle: 'Highlights from Demo Art Event 2',
              photoCount: 3,
              date: '8/21/2025',
              imageUrl: 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?q=80&w=800&auto=format&fit=crop',
              images: [
                GalleryImageItem(
                  title: 'Event Image 1',
                  imageUrl: 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?q=80&w=1200&auto=format&fit=crop',
                  caption: 'Festival crowd viewing outdoor installation',
                ),
                GalleryImageItem(
                  title: 'Event Image 2',
                  imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=1200&auto=format&fit=crop',
                  caption: 'Live performance and acoustic session',
                ),
                GalleryImageItem(
                  title: 'Event Image 3',
                  imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=1200&auto=format&fit=crop',
                  caption: 'Event highlight',
                ),
              ],
            ),
          ],
        ),
        ArtEventModel(
          id: 'movie-in-dubai',
          title: 'Movie in Dubai',
          category: 'Art Exhibition',
          price: 'Free',
          description: 'This is a test Movie event',
          requirements: 'This is a iMbu Event',
          dateTime: 'Thu, 4 Sep 2025 at 10:00 AM',
          formattedDate: 'Thursday, 4 September 2025',
          timeRange: '10:00 AM - 02:00 AM',
          location: 'Dubai',
          locationCity: 'Dubai, UAE',
          attendeesCount: 0,
          maxAttendees: 150,
          organizer: 'iMbu Event',
          organizerEmail: 'info@imbu-event.com',
          tags: ['art', 'exhibition'],
          galleries: [
            EventPhotoGallery(
              title: 'Alien Event gallery',
              subtitle: 'Gallery preview 1',
              photoCount: 2,
              date: '8/21/2025',
              imageUrl: 'https://images.unsplash.com/photo-1577896851231-70ef18881754?q=80&w=800&auto=format&fit=crop',
            ),
            EventPhotoGallery(
              title: 'Alien event gallery',
              subtitle: 'Gallery preview 2',
              photoCount: 3,
              date: '8/21/2025',
              imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=800&auto=format&fit=crop',
            ),
          ],
        ),
        ArtEventModel(
          id: '1',
          title: 'Demo Art Event 1',
          category: 'Art Exhibition',
          price: '10.00 AED',
          description: 'Experience art at Demo Event 1 with creators and live showcases.',
          requirements: 'Valid ticket required at the entrance.',
          dateTime: 'Wed, 3 Sep 2025 at 01:44 PM',
          formattedDate: 'Wednesday, 3 September 2025',
          timeRange: '01:44 PM - 06:00 PM',
          location: 'City Art Center',
          locationCity: 'Paris',
          attendeesCount: 0,
          maxAttendees: 105,
          organizer: 'Artist 1',
          organizerEmail: 'artist1@dubaiart.ae',
          tags: ['art', 'demo'],
          galleries: [
            EventPhotoGallery(
              title: 'Demo Event Preview',
              subtitle: 'Live artwork showcases',
              photoCount: 4,
              date: '8/20/2025',
              imageUrl: 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=800&auto=format&fit=crop',
            ),
          ],
        ),
        ArtEventModel(
          id: '2',
          title: 'Showcase Talent',
          category: 'Art Fair',
          price: 'Free',
          description: 'Showcase your talent and connect with international art collectors.',
          requirements: 'Portfolio submission upon registration.',
          dateTime: 'Thu, 4 Sep 2025 at 04:00 PM',
          formattedDate: 'Thursday, 4 September 2025',
          timeRange: '04:00 PM - 09:00 PM',
          location: 'Dubai Design District (d3)',
          locationCity: 'Dubai',
          attendeesCount: 12,
          maxAttendees: 200,
          organizer: 'Dubai Culture Authority',
          organizerEmail: 'culture@dubai.gov.ae',
          tags: ['showcase', 'talent', 'fair'],
          galleries: [
            EventPhotoGallery(
              title: 'd3 Creative Spaces',
              subtitle: 'Creative hubs and pavilions',
              photoCount: 5,
              date: '8/22/2025',
              imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=800&auto=format&fit=crop',
            ),
          ],
        ),
        ArtEventModel(
          id: '4',
          title: 'Photo Art Event 5',
          category: 'Photography Exhibition',
          price: 'Free',
          description: 'Exclusive gallery presentation of contemporary street & architectural photography.',
          dateTime: 'Sat, 6 Sep 2025 at 06:00 PM',
          formattedDate: 'Saturday, 6 September 2025',
          timeRange: '06:00 PM - 10:00 PM',
          location: 'Alserkal Avenue',
          locationCity: 'Dubai',
          attendeesCount: 28,
          maxAttendees: 150,
          organizer: 'Artist 5',
          tags: ['photography', 'dubai', 'gallery'],
        ),
      ];
}
