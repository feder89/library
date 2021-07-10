import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { WholesalersComponent } from './wholesalers.component';

describe('WholesalersComponent', () => {
  let component: WholesalersComponent;
  let fixture: ComponentFixture<WholesalersComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ WholesalersComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(WholesalersComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
