import { TestBed } from '@angular/core/testing';

import { WholesalerService } from './wholesaler.service';

describe('WholesalerService', () => {
  beforeEach(() => TestBed.configureTestingModule({}));

  it('should be created', () => {
    const service: WholesalerService = TestBed.get(WholesalerService);
    expect(service).toBeTruthy();
  });
});
