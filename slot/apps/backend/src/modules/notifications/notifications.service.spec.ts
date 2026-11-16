import { NotificationsService } from "./notifications.service";

describe("NotificationsService", () => {
  const notificationRepository = {
    count: jest.fn(),
    update: jest.fn(),
  };
  const deviceRepository = {};
  let service: NotificationsService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new NotificationsService(
      notificationRepository as any,
      deviceRepository as any,
    );
  });

  it("returns only the signed-in user's unread count", async () => {
    notificationRepository.count.mockResolvedValue(4);

    await expect(service.getUnreadCount("user-1")).resolves.toEqual({
      count: 4,
    });
    expect(notificationRepository.count).toHaveBeenCalledWith({
      where: { user_id: "user-1", is_read: false },
    });
  });

  it("marks only the signed-in user's unread notifications as read", async () => {
    notificationRepository.update.mockResolvedValue({ affected: 3 });

    await expect(service.markAllRead("user-1")).resolves.toEqual({
      status: "updated",
    });
    expect(notificationRepository.update).toHaveBeenCalledWith(
      { user_id: "user-1", is_read: false },
      { is_read: true },
    );
  });
});
